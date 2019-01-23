# frozen_string_literal: true
require 'test_helper'

class CommentWorkerTest < ActiveSupport::TestCase
  setup do
  	@user = create(:user)
    @comment = create(:comment)
  end

  test 'Posts a comment ' do
    #assert that a request happened
    stub_request(:post, "#{@comment.subject.url}/comments").
    	to_return({ status: 200, body: file_fixture('new_comment.json'), headers: {'Content-Type' => 'application/json'}})
    CommentWorker.new.perform(@comment.id, @user.id, @comment.subject.id)
    #updates comments with details from response
    @comment.reload
    assert_equal(@comment.github_id, 12345)
  end

  #test that a request deletes an error 
  #stub request and raise ex

  #controler expects to see a comment get created through a  post request (in the notifications controller int test)
  #should ahve enqueued a job, use stub to stub commetn on GH

end
