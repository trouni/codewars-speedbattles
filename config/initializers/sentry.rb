Sentry.init do |config|
  config.dsn = 'https://b0d72666a4ff46ffabcc1da0f1bf599b@o480835.ingest.sentry.io/5752282'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.5
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end