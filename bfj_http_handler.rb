require_relative 'http_handler'

class DefaultHttpHandler < HttpHandler

    EXTENSIONS.insert(0, '.rml')

    # Overwritten
    def handle_request(socket, request_type, request_args)
        path = request_args[0].split('/')
        case request_type
        when :HEAD
            handle_head(socket)
        when :POST
            handle_post(socket, path)
        when :GET
            handle_get(socket, path)
        end
    end

    def handle_head(socket)
        no_content(socket)
    end

    def handle_post(socket, path)
        no_content(socket)

        # post_headers = {}
        # loop do
        #     line = socket.gets.split(' ', 2)
        #     break if line[0] == ""
        #     post_headers[line[0].chop] = line[1].strip
        # end
        # post_body = socket.read(post_headers["Content-Length"].to_i)

        # data = Hash[post_body.split(/\&/).map{ |pair| pair.split("=") }]

        # p data

        # handle data, do creation or whatever
        # return location to new data if relevant

        # location = 'foo/bar'
        # socket.print http_header(201, "Created", {"Location"=>"#{location}"})
        # socket.print EMPTY_LINE

        # or alternatively, give a no content response
    end

    def handle_get(socket, path)
        serve_file(socket, path)
    end

end