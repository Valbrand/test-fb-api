class RequestWorker
	include Sidekiq::Worker

	def perform(data)
		puts data
	end
end