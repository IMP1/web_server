require_relative 'http_handler'
require_relative 'scaffold'

class ScaffoldingHttpHandler < HttpHandler

    def get_controller_type(route)
        valid_controllers = Controller.controllers.select { |c| c.match_path?(route) }
        return valid_controllers.first
    end

    # Overwritten
    def handle_request(socket, request_type, request_args)
        path = request_args[0][1..-1]
        @logger.log(path, @logger.class::TRACE)
        model = {} # TODO: get model somehow
        
        controller_type = get_controller_type(path)

        path = path[controller_type.route_prefix.size..-1]
        path = path[1..-1]

        if controller_type.nil?
            file_not_found(socket)
        else
            controller = controller_type.new(model)
            response = controller.handle_request(request_type, path)
            # TODO handle response
        end
    end

end