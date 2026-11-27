# frozen_string_literal: true
require 'test_helper'

class CommentWorkerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @comment = create(:comment)
  end

  test 'enqueues a comment' do
    CommentWorker.perform_async(@comment.id, @user.id, @comment.subject.id)
    assert_sidekiq_job_enqueued(CommentWorker, @comment.id, @user.id, @comment.subject.id)
  end

  test 'Posts and synchronises a comment with GitHub' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 200, body: file_fixture('new_comment.json'), headers: {'Content-Type' => 'application/json'}})
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    #updates comments with details from response
    @comment.reload
    assert_equal(@comment.github_id, 12345)
  end

  test 'Recovers and retries if service is unavailable' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 503})
    CommentWorker.perform_async(@comment.id, @user.id, @comment.subject.id)
    assert_sidekiq_job_enqueued(CommentWorker, @comment.id, @user.id, @comment.subject.id)
  end

  test 'Destroys and comment if the subject no longer exists' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 404})
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    assert_raises(ActiveRecord::RecordNotFound) do
      @comment.reload
    end
  end

  test 'keeps the comment when GitHub cannot be reached' do
    pending = create(:comment, github_id: nil)
    post = stub_request(:post, "#{pending.subject.url}/comments").to_timeout

    assert_nothing_raised { CommentWorker.new.perform(pending.id, @user.id, pending.subject.id) }

    assert_requested post
    assert_nil pending.reload.github_id
  end

  test 'destroys the comment when the user no longer exists' do
    pending = create(:comment, github_id: nil)

    CommentWorker.new.perform(pending.id, 0, pending.subject.id)

    refute Comment.exists?(pending.id)
  end

  test 'Sets comment count to zero (not nill) when removing the first comment' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 404})
    assert @comment.subject.comment_count = 1
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    assert @comment.subject.commentable?
  end

end
