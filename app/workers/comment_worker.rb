class CommentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :comments, unique: :until_and_while_executing

  def perform(comment_id, user_id, subject_id)
  	comment = Comment.find_by_id(comment_id)
    user = User.find_by_id(user_id)
    subject = Subject.find_by_id(subject_id)
    subject.comment_on_github(user, comment) if comment && user && subject && subject.commentable?
  end
end
