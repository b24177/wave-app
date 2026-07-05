require 'test_helper'

class SmokeRoutesTest < ActionDispatch::IntegrationTest
  test 'home page loads' do
    get '/'

    assert_response :success
  end

  test 'devise auth pages load' do
    get '/users/sign_in'
    assert_response :success

    get '/users/sign_up'
    assert_response :success

    get '/users/password/new'
    assert_response :success
  end
end
