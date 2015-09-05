class Database
	def initialize(filename, klass)
		@filename = filename
		if File.exist?(filename)
			arr = from_json(load(filename), klass)
			@data = Hash[arr.map { |i| [i.id, i] }]
		else
			@data = {}
		end
	end

	def get(id)
		@data[id]
	end

	def put(obj, do_query_data=true)
		if do_query_data and obj.respond_to?(:query_data)
			obj.query_data
		end

		@data[obj.id] = obj
	end

	def remove(id)
		@data.delete(id)
	end

	def query_put_get(obj)
		o = get(obj.id)
		if o.nil?
			put(obj, true)
			get(obj.id)
		else
			o
		end
	end

	def persist()
		save(json(@data.values), @filename)
	end

	def size
		@data.keys.size
	end
end
