module NotificationsConcern
  extend ActiveSupport::Concern

  def load_and_count_notifications(scope = notifications_for_presentation.newest)
    count_notifications(scope)
    @unread_count = user_unread_count
    load_notifications(scope)
  end

  def load_notifications(scope = notifications_for_presentation.newest)
    scope = current_notifications(scope)
    check_out_of_bounds(scope)


    @pagy, @notifications = pagy(scope, items: per_page, page: page_param, size: [1,2,2,1])
    @total = @pagy.count

    @cur_selected = [per_page, @total].min
    return scope
  end

  def count_notifications(scope)
    @types                 = scope.reorder(nil).distinct.group(:subject_type).count
    @unread_notifications  = scope.reorder(nil).distinct.group(:unread).count
    @reasons               = scope.reorder(nil).distinct.group(:reason).count
    @unread_repositories   = scope.reorder(nil).distinct.group(:repository_full_name).count

    @states                = scope.reorder(nil).distinct.joins(:subject).group('subjects.state').count
    @statuses              = scope.reorder(nil).distinct.joins(:subject).group('subjects.status').count
    @unlabelled            = scope.reorder(nil).unlabelled.count
    @bot_notifications     = scope.reorder(nil).bot_author.count
    @draft                 = scope.reorder(nil).draft.count
    @assigned              = scope.reorder(nil).assigned(current_user.github_login).count
    @visiblity             = scope.reorder(nil).distinct.joins(:repository).group('repositories.private').count
    @repositories          = Repository.where(full_name: scope.reorder(nil).distinct.pluck(:repository_full_name)).select('full_name,private')
  end

  def user_unread_count
    current_user.notifications.inbox.distinct.group(:unread).count.fetch(true){ 0 }
  end

  def selected_notifications
    if params[:id] == ['all']
      current_notifications
    else
      current_user.notifications.where(id: params[:id])
    end
  end

  def current_notifications(scope = notifications_for_presentation)
    [:repo, :reason, :type, :unread, :owner, :state, :number, :author, :is_private, :status, :draft].each do |sub_scope|
      next unless params[sub_scope].present?
      # This cast is required due to a bug in type casting
      # TODO: Rails 5.2 was supposed to fix this:
      # https://github.com/rails/rails/commit/68fe6b08ee72cc47263e0d2c9ff07f75c4b42761
      # but it seems that the issue persists when using MySQL
      # https://github.com/rails/rails/issues/32624
      if sub_scope == :reason
        val = params[sub_scope].split(',')
      else
        val = scope.klass.type_for_attribute(sub_scope.to_s).cast(params[sub_scope])
      end
      scope = scope.send(sub_scope, val)
    end
    scope = scope.unlabelled if params[:unlabelled].present?
    scope = scope.bot_author(params[:bot]) if params[:bot].present?
    scope = scope.label(params[:label]) if params[:label].present?
    scope = scope.assigned(params[:assigned]) if params[:assigned].present?
    scope
  end

  def notifications_for_presentation
    @search = Search.initialize_for_saved_search(query: params[:q], user: current_user, params: params)

    if params[:q].present?
      @search.results
    elsif params[:starred].present?
      @search.scope.starred
    elsif params[:archive].present?
      @search.scope.archived
    else
      @search.scope.inbox
    end
  end

  def check_out_of_bounds(scope)
    return unless page > 1
    total_pages = (scope.count / per_page.to_f).ceil
    page_num = [page, total_pages].min
    redirect_params = params.permit!.merge(page: page_num)
    redirect_to url_for(redirect_params) if page_num != page
  end

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def authenticate_web_or_api!
    return if logged_in?
    respond_to do |format|
      format.html { render 'pages/home' }
      format.json { authenticate_user! }
    end
  end

  def page
    @page ||= page_param
  end

  def per_page
    @per_page ||= restrict_per_page
  end

  DEFAULT_PER_PAGE = 20

  def restrict_per_page
    per_page = per_page_param || per_page_cookie || DEFAULT_PER_PAGE
    
    return DEFAULT_PER_PAGE if per_page < 1
    raise ActiveRecord::RecordNotFound if per_page > 100
    cookies[:per_page] = per_page

    per_page
  end

  def page_param
    pge = Integer(params[:page]) rescue 1
    pge < 1 ? 1 : pge
  end

  def per_page_param
    Integer(params[:per_page]) rescue nil
  end

  def per_page_cookie
    Integer(cookies[:per_page]) rescue nil
  end
end
