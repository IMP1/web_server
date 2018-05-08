class ActionResult

    class View < ActionResult
    end

    class HttpStatus < ActionResult
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

    def initialize(http_method, controller, path, arity, block_body)
        @http_method = http_method
        @controller  = controller
        @path        = path
        @arity       = arity
        @handler     = block_body
    end

    def call(*args)
        @handler.call(*args)
    end

    def match_method(http_method)
        return @http_method == http_method
    end

    def match_path(path)
        return path == @path
        # @TOCO: check for things like the following
        #        @path = "/user/{int}/profile" | path = "user/4/profile"
        #        as these should match (or at least this would be useful functionality.)
    end

    def match_args(args)
        return args.size == @arity
        # @TODO: check ranges of argument-counts (for optional args)
    end

end

class Controller

    class << self
        attr_accessor :actions
        attr_accessor :route_prefix
    end
  
    @actions      = []
    @route_prefix = ""

    @@controllers = []

    def self.controllers
        return @@controllers
    end

    def self.match_path?(path)
        return path.start_with?(self.route_prefix)
    end

    MULTIPLE_ACTION_SOULTION = :LAST # Options are :FIRST, :LAST, :ERROR

    attr_reader :model

    def initialize(model)
        @log      = Logger.new(self.class.name)
        @model    = model
    end

    def handle_request(request_type, location, *args)
        # @TODO: strip path of the controllers route prefix?
        path = self.class.route_prefix + "/" + location
        possible_actions = self.class.actions.select { |a| a.match_method(request_type) && a.match_path(path) && a.match_args(args) }
        if possible_actions.empty?
            p request_type
            p path
            p args
            return http_status(404)
        else
            case MULTIPLE_ACTION_SOULTION
            when :FIRST
                warning_message = "There were multiple possible actions for #{location} with #{args.join(', ')}."\
                "Defaulting to the first.\nTo change this behaviour, see Controller::MULTIPLE_ACTION_SOULTION."
                @log.warn(warning_message)
                return possible_actions.first.call(*args)
            when :LAST
                warning_message = "There were multiple possible actions for #{location} with #{args.join(', ')}."\
                "Defaulting to the last.\nTo change this behaviour, see Controller::MULTIPLE_ACTION_SOULTION."
                @log.warn(warning_message)
                return possible_actions.last.call(*args)
            else
                error_message = "There were multiple possible actions for #{location} with #{args.join(', ')}."\
                "To change this behaviour to just emit warnings, see Controller::MULTIPLE_ACTION_SOULTION."
                @log.error(error_message)
                return http_status(500)
            end
        end
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
        raise NotImplementedError
        # return ActionResult::HttpStatus.new(status_code, message)
    end

    def self.ROUTE(path)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.route_prefix = path
    end

    def self.GET(path, &block)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.actions ||= []
        self.actions.push(Action.new(:GET, self, path, block.arity, block))
    end

    def self.POST(path, &block)
        @@controllers.push(self) if !@@controllers.include?(self)
        self.actions ||= []
        self.actions.push(Action.new(:POST, self, path, block.arity, block))
    end

end

# This would be in a separate file.
class UserController < Controller

    ROUTE 'user'

    GET 'profile/{id}' do |id|
        user = model.read('user').select { |f| f.id == id }
        return view("user/profile/", id)
    end

    POST 'new' do |email, name|
        id = model.create('user', {name: name, email: email})
        return redirect("profile/#{id}")
    end

    POST 'edit/{id}' do |id, ammendments|
        model.update('user', id, ammendments)
        return redirect("profile/#{id}")
    end

end

# @TODO: decide on routing the controller actions
#        have a routing file? which sets locations of views and controllers
# @TODO: decide on how models are gonna work. Where'll they be defined?
