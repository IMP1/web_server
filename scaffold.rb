class ActionResult

    class View < ActionResult
    end

    class HttpStatus < ActionResult
        attr_reader :status_code
        attr_reader :message
        def initialize(status_code, message)
            @status_code = status_code
            @message = message
        end
    end

    class Content < ActionResult
    end

    class FileStream < ActionResult
    end

    class FileBinary < ActionResult
    end

end


class Action

    METHODS = [:GET, :POST, ] # @TODO: Add others

    attr_reader :param_names

    def initialize(http_method, controller, path, parameters, block_body)
        @http_method  = http_method
        @controller   = controller
        @path         = path
        @path_pattern = Regexp.new path.gsub(/\{(\w+?)\}/) { "(?<#{$1}>.+?)" }
        @arity        = parameters.size
        @param_names  = parameters.map { |p| p[1].to_s }
        @handler      = block_body
    end

    def call(*args)
        @handler.call(*args)
    end

    def match_method?(http_method)
        return @http_method == http_method
    end

    def match_path(path)
        return path.match(@path_pattern)
    end

    def match_args?(args)
        return args.size == @arity
        # @TODO: check ranges of argument-counts (for optional args)
    end

end

class Controller

    class << self
        attr_accessor :actions
        attr_accessor :route_prefix
        attr_accessor :model
    end
  
    @actions      = []
    @route_prefix = ""
    @model        = nil

    @@controllers = []

    def self.controllers
        return @@controllers
    end

    def self.match_path?(path)
        return path.start_with?(self.route_prefix)
    end

    MULTIPLE_ACTION_SOULTION = :LAST # Options are :FIRST, :LAST, :ERROR

    def initialize(model)
        @logger = Logger.new(self.class.name)
        self.class.model  = model
    end

    def handle_request(request_type, location)
        possible_actions = self.class.actions.select { |a| a.match_method?(request_type) }
        args = {}
        possible_actions = possible_actions.select { |a| args[a] = a.match_path(location) } # && a.match_args?(args)
        possible_actions = possible_actions.select { |a| a.match_args?(args[a].named_captures) }
        if possible_actions.empty?
            path = self.class.route_prefix + "/" + location
            @logger.debug("Returned a 404 for #{path}.")
            return http_status(404, "No response to request for #{path}.")
        else
            case MULTIPLE_ACTION_SOULTION
            when :FIRST
                warning_message = "There were multiple possible actions for #{location}."\
                "Defaulting to the first.\nTo change this behaviour, see Controller::MULTIPLE_ACTION_SOULTION."
                @logger.warn(warning_message)
                perform_action(possible_actions.first, args[possible_actions.first])
            when :LAST
                warning_message = "There were multiple possible actions for #{location}."\
                "Defaulting to the last.\nTo change this behaviour, see Controller::MULTIPLE_ACTION_SOULTION."
                @logger.warn(warning_message)
                perform_action(possible_actions.last, args[possible_actions.last])
            else
                error_message = "There were multiple possible actions for #{location}."\
                "To change this behaviour to just emit warnings, see Controller::MULTIPLE_ACTION_SOULTION."
                @logger.error(error_message)
                return http_status(500, "")
            end
        end
    end

    def perform_action(action, arg_match)
        args = []
        puts "----"
        p arg_match
        arg_match.named_captures.each { |name, value| args[action.param_names.index(name)] = value }
        p args
        puts "----"
        return action.call(*args)
    end

    def redirect(location, *args)
        handle_request(location, *args)
    end
    
    def view(path, *args)
        raise NotImplementedError
        # return ActionResult::View.new
    end

    def file(filename)
        raise NotImplementedError
        # return ActionResult::FileStream.new
    end

    def content(type, encoding, body)
        raise NotImplementedError
        # return ActionResult::Content.new
    end

    def http_status(status_code, message)
        return ActionResult::HttpStatus.new(status_code, message)
    end

    def self.ROUTE(path)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.route_prefix = path
    end

    def self.GET(path, &block)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.actions ||= []
        self.actions.push(Action.new(:GET, self, path, block.parameters, block))
    end

    def self.POST(path, &block)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.actions ||= []
        self.actions.push(Action.new(:POST, self, path, block.parameters, block))
    end

end

# This would be in a separate file.
class UserController < Controller

    ROUTE 'user'

    GET 'profile/{id}' do |id|
        user = model.read('user').select { |f| f.id == id.to_i }
        return view("user/profile/", id.to_i)
    end

    POST 'new' do |email, name|
        id = model.create('user', {name: name, email: email})
        return redirect("profile/#{id}")
    end

    POST 'edit/{id}' do |id, ammendments|
        model.update('user', id.to_i, ammendments)
        return redirect("profile/#{id.to_i}")
    end

end

# @TODO: decide on routing the controller actions
#        have a routing file? which sets locations of views and controllers
# @TODO: decide on how models are gonna work. Where'll they be defined?
