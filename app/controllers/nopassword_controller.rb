class NopasswordController < ApplicationController

  def send_login_email
    email = request[:email]
    remote_ip = request.remote_ip
    user_agent = request.env["HTTP_USER_AGENT"]
    host = request.host
    LoginSession.create_session(email, remote_ip, user_agent, host)
    flash[:notice] = "We sent an email to %{email}" % { :email => email }
    redirect_to '/'
  end

  def login
    id = request[:id]
    code = request[:code]
    remote_ip = request.remote_ip
    user_agent = request.env["HTTP_USER_AGENT"]
    login_session = LoginSession.find_by_id(id)
    if !login_session
      flash[:notice] = "That's not a valid login link."
    elsif login_session.activated? || login_session.terminated?
      flash[:notice] = "That code is already used."
    elsif login_session.expired?
      flash[:notice] = "That code is old as shit."
    elsif !login_session.activate_session(code, remote_ip, user_agent)
      flash[:notice] = "That code sucked."
    else
      session[:login_session] = login_session.id
    end
    redirect_to '/'
  end

  def logout
    @current_session.logout
    session[:login_session] = nil
    redirect_to '/'
  end

  def revoke
    id = request[:id]
    @current_session.revoke(id)
    render :json => { :success => :true } 
  end
end