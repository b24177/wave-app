require 'test_helper'

class AuthSessionFlowTest < ActionDispatch::IntegrationTest
  test 'user can sign in sign out and sign in again' do
    password = 'WaveSanity!2026'
    user = User.create!(
      email: "auth-flow-#{SecureRandom.hex(6)}@example.com",
      password: password,
      password_confirmation: password
    )

    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    get '/profile'
    assert_response :success

    delete destroy_user_session_path
    assert_response :redirect
    follow_redirect!
    assert_response :success

    get '/profile'
    assert_response :redirect

    post user_session_path, params: {
      user: {
        email: user.email,
        password: password
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    get '/profile'
    assert_response :success
  end
end
