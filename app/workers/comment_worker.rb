class CommentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :comments, unique: :until_and_while_executing

  def perform(comment_id, user_id, subject_id)
  	comment = Comment.find_by_id(comment_id)
    user = User.find_by_id(user_id)
    subject = Subject.find_by_id(subject_id)
    if comment && user && subject && subject.commentable?
    	subject.comment_on_github(comment, user) 
    else
    	# comment.try(:destroy)
    end
  end
end
