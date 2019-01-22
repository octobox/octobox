class CommentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :comments, unique: :until_and_while_executing

  def perform(user_id, subject_id, comment_body)
    user = User.find_by_id(user_id)
    subject = Subject.find_by_id(subject_id)
    Subject.comment_on_github(user, subject, comment_body) if user && subject && subject.commentable?
  end
end
