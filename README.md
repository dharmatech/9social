
# 9social

Small, experimental, local-first, decentralized social network

 - Follow users
 - Reply to posts
 - Upvote posts
 - Write posts

 - Why small?
   - Current client less than 3000 lines of code

 - Implemented on Plan9
   - I wanted to explore Plan9
   - Long time user of Emacs
     - I wanted to explore Acme
       - Wanted to explore Acme's extensibility
   - Mostly written in `rc`
   - This 9social client is designed for Plan9
     - Clients can be implemented for other operating systems

  - How is it decentralized?
    - No central authority or server
    - Each user's data is stored in git
      - They can use any git server they choose

 - local first
   - To read posts
     - Posts from users you follow are all downloaded
       - (for each user, `git pull`)
   - To write posts
     - Write posts locally
       - When ready to go live, system does `git push`

  - timeline view
    - chronological list of posts from everyone you follow

  - Designed to work within acme
    - View timeline
    - Open posts
    - Write posts
    - Reply to posts
    - Upvote posts           


Inspired by:
 org-social
   which is in turn inspired by
      ...







9social     org-social
            HTTP

org-social
    User's posts are in one large org mode file.

9social
    Each post in it's own file

org-social
    User's posts file served by HTTP

9social
    User's posts stored in git


- I've tested having user profiles on github
  - That's the most popular git host
  - Let me know if you try out other git hosting services