# Feature Develoment:
1. Cookbook related Issues should be logged on Github's issue tracker, and are considered to be the source of truth. 
    1. Issues will be triaged and marked with an appropriate label (e.g. bug, enhancement, question).
    2. A corresponding internal JIRA could be logged if there needs to be internal discussion or if an internal code review is desired.
2. The issue should be worked in a branch (Outside of the cerner/cerner_splunk repo)
3. The feature is pull requested to 'stable' 
    1. The feature branch should use as few logical commits as possible with descriptive commit messages (These commits should _**not**_ reference the issue, that will be done when it is merged)
    2. A new pull request should be created referencing the original issue
4. The pull request is collectively reviewed, gathering comments and must get two or more +1's from reviewers and 1 approver who is a committer to the repo. Any raised comments are then addressed, and re-reviewed. 
5. The issue is marked for the next milestone. 
6. The pull request is merged
    1. Manually, not using the github button so that the fix version of metadata.rb can be incremented in the merge ([reference](https://github.com/cerner/cerner_splunk/issues/41#issuecomment-70569000))
    2. The merge commit text should reference the Issue and the Pull Request so that both are closed when the merge is pushed.

# Release Process:
1. A pull request of the release commit will be made to stable
    1. The release commit should contain an update of metadata.rb's version to the milestone version.
    2. The PR description will summarize what was changed since the last milestone, and propose tag text
    3. The PR will be labeled "release"
2. Pull request is reviewed with 2 +1s
3. The pull request is merged 
    1. Manually, not using github issues so a fast forward of stable can be done
    2. The annotated tag is created of the reviewed release text
    3. Master is set to the annotated tag
4. Release to supermarket 
5. Cleanup
    1. The issue and existing milestone is closed
    2. A new milestone is created for the next enhancement version
