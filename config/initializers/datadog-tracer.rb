Datadog.configure do |c|
  c.use :rails, service_name: 'octobox'
  c.tracer hostname: ENV['DD_AGENT_PORT_8126_TCP_ADDR'],
           port: ENV['DD_AGENT_PORT_8126_TCP_PORT']
end
