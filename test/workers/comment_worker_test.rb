# frozen_string_literal: true
require 'test_helper'

class CommentWorkerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @comment = create(:comment)
  end

  test 'enqueues a comment' do
    CommentWorker.perform_async(@comment.id, @user.id, @comment.subject.id)
    assert_equal 1, CommentWorker.jobs.size
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
    assert_equal 1, CommentWorker.jobs.size
  end

  test 'Destroys and comment if the subject no longer exists' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 404})
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    assert_raises(ActiveRecord::RecordNotFound) do
      @comment.reload
    end
  end

  test 'Sets comment count to zero (not nill) when removing the first comment' do
    stub_request(:post, "#{@comment.subject.url}/comments").
      to_return({ status: 404})
    assert @comment.subject.comment_count = 1
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    assert @comment.subject.commentable?
  end

end
