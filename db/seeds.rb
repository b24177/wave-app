puts "Deleting prior records"

UserArtist.delete_all
User.delete_all
Artist.delete_all
Content.delete_all
Post.delete_all

puts "Creating user"

user1 = User.create!({
  email: 'testUser@gmail.com',
  password: 'password',
  password_confirmation: 'password'
})

puts 'Creating artists'

def create_artist(attributes = {})
  artist = Artist.create!({
    name: attributes[:name],
    location: attributes[:location],
    followers: attributes[:followers],
    spotify_id: attributes[:spotify_id]
  })
  artist.photo.attach(io: File.open(attributes[:avatar]), filename: attributes[:avatar], content_type: "image/jpg")
  artist
end

lust_for_youth = create_artist({
  name: 'Lust for Youth',
  location: 'Copenhagen, Denmark',
  followers: 22161,
  spotify_id: '18x7cMASHAS2NJ4kcLJa1u',
  avatar: "app/assets/images/avatars/lfy_avatar.jpg"
})

cut_copy = create_artist({
  name: 'Cut Copy',
  location: 'Melbourne, Australia',
  followers: 274138,
  spotify_id: '4EENT7N7rCBwrddM3s0vFS',
  avatar: "app/assets/images/avatars/cut_copy_avatar.jpg"
})

girl_in_red = create_artist({
  name: 'Girl in Red',
  location: 'Oslo, Norway',
  followers: 1774168,
  spotify_id: '3uwAm6vQy7kWPS2bciKWx9',
  avatar: "app/assets/images/avatars/girl_in_red.jpg"
})

puts "Creating posts"

def create_post(attributes = {})
  post = Post.create!({
    artist: attributes[:artist],
    source: attributes[:source]
  })
  attributes[:contents].each do |content|
    post.contents.create!(content)
  end
  post
end

post1 = create_post({
  artist: lust_for_youth,
  source: 'Facebook',
  contents: [
    {format: 'text', data: 'Back in the studio!'},
    {format: 'image', data: '/posts_images/card1.jpg'}
  ]
})

Notification.create!(user: user1, post: post1)

create_post({
  artist: lust_for_youth,
  source: 'Twitter',
  contents: [
    {format: 'text', data: 'Get ready, Berlin!'}
  ]
})

create_post({
  artist: lust_for_youth,
  source: 'Instagram',
  contents: [
    {format: 'text', data: 'We had a great time, Paris!'},
    {format: 'image', data: '/posts_images/lfy_instagram.jpg'}
  ]
})

create_post({
  artist: cut_copy,
  source: 'Facebook',
  contents: [
    {format: 'text', data:'Great to be back, Australia!'},
    {format: 'image', data:'/posts_images/cut_copy_facebook.jpg'}
  ]
})

create_post({
  artist: cut_copy,
  source: 'Twitter',
  contents: [
    {format: 'text', data: 'Excited to release our new album next week!'}
  ]
})

create_post({
  artist: cut_copy,
  source: 'Instagram',
  contents: [
    {format: 'text', data: 'Getting ready for you, New York!'},
    {format: 'image', data: '/posts_images/cut_copy_instagram.jpg'}
  ]
})

create_post({
  artist: girl_in_red,
  source: 'Facebook',
  contents: [
    {format: 'text', data: 'Great to be back, Trondheim!'},
    {format: 'image', data: '/posts_images/gir_fb.jpg'}
  ]
})

create_post({
  artist: girl_in_red,
  source: 'Twitter',
  contents: [
    {format: 'text', data: 'Making this album has been an amazing experience.'}
  ]
})

create_post({
  artist: girl_in_red,
  source: 'Instagram',
  contents: [
    {format: 'text', data: 'New album cover shoot'},
    {format: 'image', data: '/posts_images/gir_instagram.jpg'}
  ]
})

puts 'Seeding done successfully'

