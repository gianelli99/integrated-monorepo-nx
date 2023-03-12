#!/bin/bash

print_usage() {
    echo "💀 $1"
    echo "Help below 👇"
    echo ""
    echo "Builds the specified project for Heroku."
    echo ""
    echo "Usage: ./heroku-build <nx-project-name>"
    echo ""
    echo "__Note that__ this script is intended to be used from CI/CD, you probably won't need it during development."
    exit 1
}

if [ -z "$1" ]; then
    print_usage "Project name is missing!"
fi

# Heroku build is a little bit different because they have a slug size (deployment size) limit of 500MB.
# If you build the project (not just the package) you'll end up with a `node_modules` folder that's ridiculously big (3GB)
# but it can't be pruned properly. If you think you can prune it without this hacky solution go ahead, but it is unlikely
# that you'll be able to figure it out. **If** you try it please increment the counter below:
# 
# total_hours_wasted_trying_to_prune_node_modules=13
# 
# So how this works is that Heroku will run `npm install --prod` that will delete devDependencies too, so
# 💀 DON'T MOVE nx and @nrwl packages to devDependencies! 💀
# After the project is built you'll have the horrendous `node_modules` folder, but it's not a big deal as we'll delete it.

# Build the project with nx
nx build $1 --prod

# This step is necessary because npm will look for `package.json` files in the parent folder and it will use the `node_modules`
# folder from the parent folder. We don't want that, we want to have only the necessary packages (backend) in the `node_modules` folder.
mv package.json package.json.bak
mv package-lock.json package-lock.json.bak

# We get rid of all the unnecessary packages.
rm -Rf node_modules

# We install the necessary packages.
# In the `nx build` step nx generates a `package.json` that only contains the dependencies of the backend project
# so this will *only* (😒) download 500MB from npm.
npm install dist/apps/backend

# More reading on this problem:
#
# - https://stackoverflow.com/questions/73373307/how-to-build-and-package-only-the-relevant-dependencies-using-nx?noredirect=1#comment129738870_73373307
# - https://github.com/nrwl/nx/issues/1518
# - https://github.com/nestjs/nest/issues/1706#issuecomment-579248915