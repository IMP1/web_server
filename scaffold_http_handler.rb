require_relative 'http_handler'
require_relative 'scaffold'

class ScaffoldingHttpHandler < HttpHandler

    def get_controller_type(route)
        return Controller.controllers.select { |c| c.match_path?(route) }.first
    end

    # Overwritten
    def handle_request(socket, request_type, request_args)
        path = request_args[0][1..-1]
        p path
        args = [] # TODO: get args for controller actions somehow
        model = [] # TODO: get model somehow
        
        controller_type = get_controller_type(path)

        p controller_type

        if controller_type.nil?
            # TODO: error? 404, probably.
            file_not_found(socket)
        else
            controller = controller_type.new(model)
            controller.handle_request(request_type, path, args)
        end
    end

    # def handle_post(socket, path)
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
    # end

end