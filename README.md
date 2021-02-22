# Korblab NMES Review
A collection of any program related to the NMES review paper

## How to use the first time

1. Use the following instruction to clone the repository to your local machine.
  - If you are on Mac, use the terminal when you are in the folder you want to use.
  - If you are on Windows, use the [git terminal](https://git-scm.com/download/win).
  - If you are not comfortable using the command line try using [Sourcetree](https://www.sourcetreeapp.com/)

```
git clone https://github.com/MonicaPH/Korblab_NMES_Review.git
```

2. The command in 1) will create a new folder with the repository inside. </br>
Go to that folder using the change directory command ```cd Korblab_NMES_Review``` in the terminal.

3. You can modify and create files there.
  - Please do not create many versions of the same file, just modify the file you want to modify. </br>
  The whole point of git is to automatize the version control.
  - Try to make small changes, test them, and when they are working.

4. When you are done making the change, check the status of your local copy of the repository with the command below. </br>
It will show you modified files and files that are not in version control (untracked) in red.

```
git status
```

5. Add the modifications to the repository using the command below and replace the filename with the file you want to add. </br>
I strongly advise you to add file by file, to prevent garbage from getting in.

```
git add filename
```

6. Commit your work with a meaningful comment. This is, describe the changes you made.

```
git commit -m "your message"
```

7. Push your changes to the online repository so that others can see them. </br>
Check if someone else added changes before you and resolve conflicts (if you edited the same file in the same line).

```
git pull
git push
```

## How to use on subsequent times
- It is best practice to "pull" changes others "pushed" online to your local machine every day before you start working.

```
cd path/to/Korblab_NMES_Review
git pull
```

- Make your changes, and repeat steps 3 to 6.
- At the end of your day or when you want to make your changes available to others, </br>
"push" your locally commited changes as in step 7.


### [Git basics](https://rogerdudler.github.io/git-guide/)
