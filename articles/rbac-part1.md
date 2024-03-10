---
date: 2024-03-06
article_title: Relation base access control explain
article_description: Recently I had to implement a complex permission system at work. This was a funny and exciting experience so I want to share with you the "Why" and the "How" about this journey.
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

Let's take a simple example of a company that need to secure access to confidential documents. The system should know if a user can `read` and/or `edit` a document. Let's imagine Bob is working in the
company and should access in `edit` mode to a document `sales.xlsx`, we could modelize it as a DAG:

<pre class="mermaid mermaid-stuff">
---
config:
  theme: base
  themeVariables:
    primaryTextColor: "black"
    edgeLabelBackground: "transparent"
---
flowchart TB
    B((Bob)):::user
    D((sales.xslx)):::doc
    B -->|edit| D

    classDef user r:50px,fill:white,stroke:#cc241d,stroke-width:4px
    classDef group r:50px,fill:white,stroke:#b16261,stroke-width:4px
    classDef folder r:50px,fill:white,stroke:#458588,stroke-width:4px
    classDef doc fill:white,stroke:#98971a,stroke-width:4px
</pre>

So far so good, Bob need access to a document, we give him the access, fine! But Bob is the manager of the Sales team of the company, his team need `read` access to `sales.xlsx`. In his team,
peoples can join, other can leave, so managing individual access isn't an option. Let's introduce another type of node `Group`:

<pre class="mermaid mermaid-stuff">
---
config:
  theme: base
  themeVariables:
    primaryTextColor: "black"
    edgeLabelBackground: "transparent"
---
flowchart TB
    B((Bob)):::user
    A((Alice)):::user
    D((sales.xslx)):::doc
    G((Sales)):::group
    B -->|edit| D
    B -->|member| G
    A -->|member| G
    G -->|read| D

    classDef user r:50px,fill:white,stroke:#cc241d,stroke-width:4px
    classDef group r:50px,fill:white,stroke:#b16261,stroke-width:4px
    classDef folder r:50px,fill:white,stroke:#458588,stroke-width:4px
    classDef doc fill:white,stroke:#98971a,stroke-width:4px
</pre>

Fine! we are able to manage permission on `User` and `Group` now. But we still miss something: `Group` help us to manage a dynamic human organization but what about our documents? In the same way,
document can be added / removed and managing access to individual document could quickly become impossible. We need to represent a folder hierarchy in our system. Now, let's dive in a more real use case,
let's imagine that our sales team have multiple documents with different concerns:

* The revenues documents: These are a bunch of excel spreadsheet that Bob (as manager) edit to give an overview of the performance of the team each quarter. Obviously Bob need edit access to this document
but the rest of the team can just read it.
* The customer documents contains information on different prospect that the team is working on. It's important that every people of the sales team can edit it to add information about those clients.

So our permission system should implement those requirements:
* Every people in the sales team should be able to read every documents related to the team
* Only bob should be able to edit revenues's documents
* Every people of the sales team should be able to edit customers related documents.

Here is a graph that represent these requirements. We introduced 3 folders in our system. The `docs` folder is the root folder of every document owned by the sales team: every new document or folder will be added to these root folder.
A own edge link every folder/document to its parent node. If a user or a group have a permission defined on a folder, the permission is applied transitively to every childs of the folder.

<pre class="mermaid mermaid-stuff">
---
config:
  theme: base
  themeVariables:
    primaryTextColor: "black"
    edgeLabelBackground: "transparent"
---
flowchart TB

    B((Bob)):::user
    A((Alice)):::user

    D1((q1_sales.xslx)):::doc
    D2((q2_sales.xslx)):::doc
    D4((companyX.docx)):::doc
    D5((companyY.docx)):::doc

    F1((docs)):::folder
    F2((customers)):::folder
    F3((revenues)):::folder

    G((Sales)):::group

    B -->|member| G
    A -->|member| G
    G -->|read| F1
    B -->|edit| F3
    F1 -->|own| F2 & F3
    G -->|edit| F2
    F2 -->|own| D4 & D5
    F3 -->|own| D1 & D2

    classDef user r:50px,fill:white,stroke:#cc241d,stroke-width:4px
    classDef group r:50px,fill:white,stroke:#b16261,stroke-width:4px
    classDef folder r:50px,fill:white,stroke:#458588,stroke-width:4px
    classDef doc fill:white,stroke:#98971a,stroke-width:4px
</pre>


Now, let's try to understand how our resolution algorithm would work on these model. TODO

Finally we have a minimal real use case for our permission system where we have the following entities:
* **User**: A user can have permissions access to resources and be member of group(s).
* **Group**: A group can contains one or multiple users and give access to resource(s).
* **Scope**: A scope can own resource(s) and child scope(s), it can give transitive permissions to its childs. We talk about folder previously, this is a special case of scope.
* **Resources**: An entity on which we want to grant access to. In the example above, we talk about Document, but this is a special case of resources entity.

