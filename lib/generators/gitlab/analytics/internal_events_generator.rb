# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  module Analytics
    class InternalEventsGenerator < Rails::Generators::Base
      TIME_FRAME_DIRS = {
        '7d' => 'counts_7d',
        '28d' => 'counts_28d'
      }.freeze

      TIME_FRAMES_DEFAULT = TIME_FRAME_DIRS.keys.tap do |time_frame_defaults|
        time_frame_defaults.class_eval do
          def to_s
            join(", ")
          end
        end
      end.freeze

      ALLOWED_TIERS = %w[free premium ultimate].dup.tap do |tiers_default|
        tiers_default.class_eval do
          def to_s
            join(", ")
          end
        end
      end.freeze

      NEGATIVE_ANSWERS = %w[no n No NO N].freeze
      POSITIVE_ANSWERS = %w[yes y Yes YES Y].freeze
      TOP_LEVEL_DIR = 'config'
      TOP_LEVEL_DIR_EE = 'ee'
      DESCRIPTION_MIN_LENGTH = 50
      KNOWN_EVENTS_PATH = 'lib/gitlab/usage_data_counters/known_events/common.yml'
      KNOWN_EVENTS_PATH_EE = 'ee/lib/ee/gitlab/usage_data_counters/known_events/common.yml'

      DESCRIPTION_INQUIRY = %(
        Please describe in at least #{DESCRIPTION_MIN_LENGTH} characters
        what %{entity} %{entity_type} represents,
        consider mentioning: %{considerations}.
        Your answer will be processed by a full-text search tool and help others find and reuse this %{entity_type}.
      ).freeze

      source_root File.expand_path('../../../../generator_templates/gitlab_internal_events', __dir__)

      desc 'Generates metric definitions, event definition yml files and known events entries'

      class_option :skip_namespace,
        hide: true
      class_option :skip_collision_check,
        hide: true
      class_option :time_frames,
        optional: true,
        default: TIME_FRAMES_DEFAULT,
        type: :array,
        banner: TIME_FRAMES_DEFAULT,
        desc: "Indicates the metrics time frames. Please select one or more from: #{TIME_FRAMES_DEFAULT}"
      class_option :tiers,
        optional: true,
        default: ALLOWED_TIERS,
        type: :array,
        banner: ALLOWED_TIERS,
        desc: "Indicates the metric's GitLab subscription tiers. Please select one or more from: #{ALLOWED_TIERS}"
      class_option :group,
        type: :string,
        optional: false,
        desc: 'Name of group that added this metric'
      class_option :stage,
        type: :string,
        optional: false,
        desc: 'Name of stage that added this metric'
      class_option :section,
        type: :string,
        optional: false,
        desc: 'Name of section that added this metric'
      class_option :mr,
        type: :string,
        optional: false,
        desc: 'Merge Request that adds this metric'
      class_option :event,
        type: :string,
        optional: false,
        desc: 'Name of the event that this metric counts'
      class_option :unique,
        type: :string,
        optional: false,
        desc: 'Name of the event property that this metric counts'

      def create_metric_file
        validate!

        template "event_definition.yml",
          event_file_path(event),
          ask_description(event, "event", "what the event is supposed to track, where, and when")

        time_frames.each do |time_frame|
          template "metric_definition.yml",
            metric_file_path(time_frame),
            key_path(time_frame),
            time_frame,
            ask_description(
              key_path(time_frame),
              "metric",
              "events, and event attributes in the description"
            )
        end

        # ToDo: Delete during https://gitlab.com/groups/gitlab-org/-/epics/9542 cleanup
        append_file known_events_file_name, known_event_entry
      end

      private

      def known_event_entry
        <<~YML
        - name: #{event}
        YML
      end

      def event_identifiers
        return unless include_default_event_properties?

        "\n- project\n- user\n- namespace"
      end

      def include_default_event_properties?
        question = <<~DESC
        By convention all events automatically include the following properties:
        * environment: string,
        * source: string (eg: ruby, javascript)
        * user_id: number
        * project_id: number
        * namespace_id: number
        * plan: string (eg: free, premium, ultimate)
        Would you like to add default properties to the event? Y(es)/N(o)
        DESC

        answer = Gitlab::TaskHelpers.prompt(question, POSITIVE_ANSWERS + NEGATIVE_ANSWERS)
        POSITIVE_ANSWERS.include?(answer)
      end

      def event_file_path(event)
        path = File.join(TOP_LEVEL_DIR, 'events', "#{event}.yml")
        path = File.join(TOP_LEVEL_DIR_EE, path) unless free?
        path
      end

      def event
        options[:event]
      end

      def ask_description(entity, type, considerations)
        say("")
        desc = ask(format(DESCRIPTION_INQUIRY, entity: entity, entity_type: type, considerations: considerations))

        while desc.length < DESCRIPTION_MIN_LENGTH
          error_msg = <<~ERROR
            Provided description is too short: #{desc.length} of required #{DESCRIPTION_MIN_LENGTH} characters
          ERROR

          say(set_color(error_msg, :red))

          desc = ask("Please provide description that is #{DESCRIPTION_MIN_LENGTH} characters long.\n")
        end
        desc
      end

      def distributions
        dist = "\n"
        dist += "- ce\n" if free?

        "#{dist}- ee"
      end

      def tiers
        "\n- #{options[:tiers].join("\n- ")}"
      end

      def milestone
        Gitlab::VERSION.match('(\d+\.\d+)').captures.first
      end

      def class_name
        'RedisHLLMetric'
      end

      def key_path(time_frame)
        "count_distinct_#{options[:unique].sub('.', '_')}_from_#{event}_#{time_frame}"
      end

      def metric_file_path(time_frame)
        path = File.join(TOP_LEVEL_DIR, 'metrics', TIME_FRAME_DIRS[time_frame], "#{key_path(time_frame)}.yml")
        path = File.join(TOP_LEVEL_DIR_EE, path) unless free?
        path
      end

      def known_events_file_name
        (free? ? KNOWN_EVENTS_PATH : KNOWN_EVENTS_PATH_EE)
      end

      def validate!
        raise "Required file: #{known_events_file_name} does not exists." unless File.exist?(known_events_file_name)
        raise "An event '#{event}' already exists" if event_exists?

        validate_tiers!

        %i[unique event mr section stage group].each do |option|
          raise "The option: --#{option} is  missing" unless options.key? option
        end

        time_frames.each do |time_frame|
          validate_time_frame!(time_frame)
          validate_key_path!(time_frame)
        end
      end

      def validate_time_frame!(time_frame)
        return if TIME_FRAME_DIRS.key?(time_frame)

        raise "Invalid time frame: #{time_frame}, allowed options are: #{TIME_FRAMES_DEFAULT}"
      end

      def validate_tiers!
        wrong_tiers = options[:tiers] - ALLOWED_TIERS
        unless wrong_tiers.empty?
          raise "Tiers option included not allowed values: #{wrong_tiers}. Only allowed values are: #{ALLOWED_TIERS}"
        end

        return unless options[:tiers].empty?

        raise "At least one tier must be present. Please set --tiers option"
      end

      def validate_key_path!(time_frame)
        return unless metric_definition_exists?(time_frame)

        raise "Metric definition with key path '#{key_path(time_frame)}' already exists"
      end

      def event_exists?
        return true if ::Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(event)

        existing_events_from_definitions.include?(event)
      end

      def existing_events_from_definitions
        events_glob_path = File.join(TOP_LEVEL_DIR, 'events', "*.yml")
        ee_events_glob_path = File.join(TOP_LEVEL_DIR_EE, events_glob_path)

        [ee_events_glob_path, events_glob_path].flat_map do |glob_path|
          Dir.glob(glob_path).map do |path|
            YAML.safe_load(File.read(path))["action"]
          end
        end
      end

      def free?
        options[:tiers].include? "free"
      end

      def time_frames
        options[:time_frames]
      end

      def directory
        @directory ||= TIME_FRAME_DIRS.find { |d| d.match?(input_dir) }
      end

      def metric_definitions
        @definitions ||= Gitlab::Usage::MetricDefinition.definitions(skip_validation: true)
      end

      def metric_definition_exists?(time_frame)
        metric_definitions[key_path(time_frame)].present?
      end
    end
  end
end
