threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

bind "unix:///home/deploy/apps/quadra-do/shared/tmp/sockets/puma.sock"
