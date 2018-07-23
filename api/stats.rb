get "#{APIPREFIX}/stats" do # retrieve threads by course
  from_time = Date.today.to_time - (params["limit_days"] or 1.months)
  response_data = {}
  request_user = nil
  if params["user_id"]
    begin
      request_user = User.find_by(external_id: params["user_id"])
    rescue Mongoid::Errors::DocumentNotFound
    end
  end
  threads = CommentThread.where({"course_id" => params["course_id"]})
  response_data["threads_count"] = threads.count
  latest_threads = threads.where(:created_at => {:$gte => from_time})
  response_data["latest_threads_count"] = latest_threads.count
  comments = Comment.where({"course_id" => params["course_id"]})
  response_data["comments_count"] = comments.count
  latest_comments = comments.where(:created_at => {:$gte => from_time})
  response_data["latest_comments_count"] = latest_comments.count
  if request_user
    threads_count_for_user = request_user ? threads.where({"author" => user}).count : 0
    response_data["user_threads_count"] = threads_count_for_user
    comments_count_for_user = request_user ? comments.where({"author" => user}).count : 0
    response_data["user_comments_count"] = comments_count_for_user
  end
  last_thread = latest_threads.asc(:created_at).last or nil
  if last_thread
    latest_comment_or_thread_data = {}
    latest_comment_or_thread_data["thread"] = last_thread
    last_comment = latest_comments.asc(:created_at).last or nil
    last_comment_thread = last_comment ? last_comment.comment_thread : nil
    if last_comment
        if last_comment.created_at >= last_thread.created_at
            latest_comment_or_thread_data["thread"] = last_comment_thread
            latest_comment_or_thread_data["comment"] = last_comment
        end
    end
    response_data["latest_comment_or_thread"] = latest_comment_or_thread_data
  end

  response_data.to_json
end