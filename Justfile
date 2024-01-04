clean:
  cd packages/web5_flutter && flutter clean

get:
  #!/bin/bash
  echo "Getting dependencies for packages"
  for dir in packages/*; do \
    if [ -d $dir ]; then \
      echo "Getting dependencies in $dir"; \
      (cd $dir && flutter pub get || dart pub get); \
    fi \
  done

test:
  #!/bin/bash
  for dir in packages/*; do \
    if [ -d $dir ]; then \
      echo "Running tests in $dir"; \
      (cd $dir && flutter test || dart test); \
    fi \
  done

analyze:
  #!/bin/bash
  for dir in packages/*; do \
    if [ -d $dir ]; then \
      (cd $dir && flutter analyze || dart analyze); \
    fi \
  done 
