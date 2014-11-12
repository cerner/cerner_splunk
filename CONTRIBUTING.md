# Feature Develoment:
1. Cookbook related Issues should be logged on Github's issue tracker, and are considered to be the source of truth. 
    1.  Issues should be triaged and marked with an appropriate label of bug, enhancement, question
    2. A corresponding internal JIRA could be logged if there needs to be internal discussion or if an internal code review is desired
2.  The issue should be worked on in a fork of this repo (Outside of the cerner/cerner_splunk repo)
    1. Working internally on OpsInfra/cerner_splunk and using Crucible reviews is OK.
3. The feature is pull requested to 'stable' 
    1. The feature branch should use as few logical commits as possible with descriptive commit messages
    2. Attach a pull request to the issue (using a tool like hub, github's ui doesn't let you do this but the API does) if it's a simple / obvious change, or create a new pull request referencing the issue if it's larger / complex. (judgement call).
4. The pull request is reviewed and gets two +1s, or is sent back for revision
5. The issue is marked for the next milestone. 
6. A merge commit is made to merge the pull request to stable and close the issue

# Release Process:
1. An issue is created in the milestone with the label of release
    1. The issue will summarize what was changed in the release, and propose a tag text
    2. The issue will include a proposed annotated tag text
2. A pull request of the preparation for release commit and the prepare for next version commit will be attached to the release issue to merge to stable (either use a tool like hub, or create the issue as a pull request up front)
3. Pull request is reviewed with 2 +1s
4. The pull request is merged 
    1. Manually, not using github issues so a fast forward of stable can be done
    2. The annotated tag is created of the reviewed release text
    3. Master is set to the annotated tag
5. Release to supermarket 
6. Cleanup
    1. The issue and existing milestone is closed
    2. A new milestone is created for the next enhancement version
7. The built cookbook is uploaded to all internal enterprise chef servers
8. Issues logged (internally) for updating the ops_chef-repo (or whatever is the decided method for updating the chef-repo.