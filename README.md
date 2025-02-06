# My Dotfiles

This repository contains my personal configuration files (dotfiles) for various applications and tools. I use a bare Git repository to manage and version these files.

## Getting Started

To clone and manage your dotfiles using a bare Git repository, follow these steps:

### 1. Clone the Repository

Clone the repository into a `dotfiles` directory in your home directory:

```sh
git clone --bare git@github.com:CreativeCodeCat/DotFiles_APTBase.git $HOME/.dotfiles
```

### 2. Define an Alias

Define an alias to simplify Git commands for managing your dotfiles:

```sh
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

### 3. Checkout the Repository

Checkout the actual content from the repository to your home directory:

```sh
dotfiles checkout
```

If you encounter errors because some files already exist, back them up or remove them before retrying the checkout command.

### 4. Configure Git to Ignore Untracked Files

Configure the repository to not show untracked files to keep your home directory clean:

```sh
dotfiles config --local status.showUntrackedFiles no
```

## Usage

With the alias defined, you can now manage your dotfiles using standard Git commands prefixed with `dotfiles`.

### Examples:

- Add a file:

  ```sh
  dotfiles add .vimrc
  ```

- Commit changes:

  ```sh
  dotfiles commit -m "Add vim configuration"
  ```

- Push changes:

  ```sh
  dotfiles push
  ```

- Pull changes:

  ```sh
  dotfiles pull
  ```

## Customization

You can customize this setup to include additional files or directories by adding them to the repository and committing the changes.

## Backup and Restore

To backup your dotfiles, simply push your changes to the remote repository. To restore them on a new machine, follow the cloning and checkout steps above.

## Additional Resources

- [Dotfiles Git Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [Managing Dotfiles with Git](https://www.anishathalye.com/2014/08/03/managing-your-dotfiles/)

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
