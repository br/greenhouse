if [ "$RACK_ENV" = "production" ]
then
  echo "Starting as app production server"
  bundle exec puma -p 80 -w 2
else
  bundle exec puma
fi
