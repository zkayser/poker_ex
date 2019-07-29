if [ $(git tag -l --points-at HEAD | awk '/[[:digit:].[:digit:].[:digit:]]/') ]
then
  echo 'Building and publish docker version $(./bin/get_version.sh) to Docker Hub'
  docker build -t zkayser/poker_ex:$(./bin/get_version.sh) .
  docker push zkayser/poker_ex:$(./bin/get_version.sh)
else
  echo 'Building and publishing Docker image for commit $(git rev-parse HEAD)'
  docker build -t zkayser/poker_ex:$(git rev-parse HEAD) .
  docker push zkayser/poker_ex:$(git rev-parse HEAD)
fi