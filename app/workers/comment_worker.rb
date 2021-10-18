class CommentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :comments, lock: :until_and_while_executing

  def perform(comment_id, user_id, subject_id)
    comment = Comment.find_by_id(comment_id)
    user = User.find_by_id(user_id)
    subject = Subject.find_by_id(subject_id)
    if comment && user && subject && subject.commentable?
      begin
        subject.comment_on_github(comment, user) 
      rescue Octokit::NotFound, Octokit::Unauthorized, Octokit::Forbidden
        comment.try(:destroy)
      rescue Faraday::Error => exception
        handle_exception(exception, user)
      end
    else
      comment.try(:destroy)
    end
  end

  private

  def handle_exception(exception, user)
    logger.error("[ERROR] CommentWorkerJob#perform #{user.github_login} - #{exception.class}: #{exception.message}")
  end
end
