require 'test_helper'

class ArtistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @password = 'password123'
    @user = User.create!(email: "artists-test-#{SecureRandom.hex(4)}@example.com", password: @password)
    sign_in_as(@user, @password)
  end

  test 'index paginates followed artists and shows next link on first page' do
    create_followed_artists_for(@user, count: 30)

    get artists_path

    assert_response :success
    assert_select 'span', text: 'Page 1 of 2'
    assert_select 'a', text: 'Next', count: 1
    assert_select 'a', text: 'Previous', count: 0
    assert_includes @response.body, 'Artist 01'
    assert_includes @response.body, 'Artist 24'
    assert_not_includes @response.body, 'Artist 25'
  end

  test 'index shows second page with previous link' do
    create_followed_artists_for(@user, count: 30)

    get artists_path(page: 2)

    assert_response :success
    assert_select 'span', text: 'Page 2 of 2'
    assert_select 'a', text: 'Previous', count: 1
    assert_select 'a', text: 'Next', count: 0
    assert_includes @response.body, 'Artist 25'
    assert_includes @response.body, 'Artist 30'
    assert_not_includes @response.body, 'Artist 24'
  end

  test 'index filters artists by query and preserves query in pagination links' do
    create_followed_artists_for(@user, count: 30)

    get artists_path(query: 'Artist 2')

    assert_response :success
    assert_select 'input[name="query"][value="Artist 2"]', count: 1
    assert_select 'a', text: 'Next', count: 0
    assert_includes @response.body, 'Artist 20'
    assert_includes @response.body, 'Artist 29'
    assert_not_includes @response.body, 'Artist 01'
  end

  test 'index shows empty search state when no matches are found' do
    create_followed_artists_for(@user, count: 5)

    get artists_path(query: 'NoSuchArtist')

    assert_response :success
    assert_includes @response.body, 'No followed artists match "NoSuchArtist".'
  end

  private

  def sign_in_as(user, password)
    post user_session_path, params: { user: { email: user.email, password: password } }
    follow_redirect! if response.redirect?
    assert_response :success
  end

  def create_followed_artists_for(user, count:)
    count.times do |index|
      artist = Artist.create!(
        name: format('Artist %<number>02d', number: index + 1),
        spotify_id: "test-spotify-#{SecureRandom.hex(8)}",
        followers: (index + 1) * 100
      )

      UserArtist.create!(user: user, artist: artist, status: 'follow')
    end
  end
end
