dir=~/dotfiles
olddir=~/dotfiles_old

files="nvim"
echo "Creating $olddir for backup"
mkdir -p $olddir

cd $dir

for file in $files; do
	mv ~/.config/$file ~/dotfiles_old/
	echo "Creating symlink to $file in home dir."
	ln -s $dir/$file ~/.config/$file
done

