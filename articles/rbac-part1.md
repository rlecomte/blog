---
date: 2024-03-06
article_title: RBAC part 1
article_description: For my first article, we will explore a solution to implement an efficient rbac system without anything but code!
---


As software engineer, I worked a lot on Web applications. Those type of applications often ask for users to authenticate first, and then, offer a bunch of access to resources on different http endpoint.
Most of the time there is two types of user: regular user and admin. When regular users consume the API to access a service, admin have to administrate this service.

Even if the Web UI don't offer any way to administrate the service for regular user, we need to secure the backend to avoid malicious call to the API. This lead to this kind of logic in Web controller:

```scala
def postNewBlogPost(userId: String, post: Post): Unit = {
    var user = user.getById(userId)
    if (user.isAdmin()) blogService.createPost(post)
    else throw new AuthorizationException(s"user $userId isn't admin.")
}
```

This is good enought most of the time, but sometimes, we can have more user's role to manage and some of them can access a same endpoints. Here for example we have three roles, `{REGULAR, MANAGER, ADMIN}`;
Both blog MANAGER and ADMIN can create a blog post, we need to add a condition:

```scala
def postNewBlogPost(userId: String, post: Post): Unit = {
    var user = user.getById(userId)
    if (user.isAdmin() || user.isManager()) blogService.createPost(post)
    else throw new AuthorizationException(s"user $userId isn't admin.")
}
```

In the case below, this is still "ok'ish" to manage role in this way. But what if we have about ten or twelve role? What if we want dynamic roles? The requirement complexity quickly reach
a limit that can't be resolved by this simple solution. We need more!

## Permission system is about human organization

BITE
