dir=~/dotfiles
olddir=~/dotfiles_old

files="nvim"
echo "Creating $olddir for backup"
mkdir -p $olddir

cd $dir

for file in $files; do
    if [ -d "~/.config/$file" ]
    then 
	    mv ~/.config/$file ~/dotfiles_old/
    fi

	echo "Creating symlink to $file in home dir."
	ln -s $dir/$file ~/.config/$file
done

