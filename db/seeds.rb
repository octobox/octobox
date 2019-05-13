#######################
# BEGIN: creating users
#######################

n_users = 100
n_users.times do |n|
  User.create!(github_id: n + 1,
               github_login: "github_login_#{n + 1}")
end

##########################
# FINISHED: creating users
##########################
