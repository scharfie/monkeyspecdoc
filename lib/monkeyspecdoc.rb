require 'test/unit'
require 'test/unit/ui/console/testrunner'

def split_shoulda_names(name)
  if /test: (.*) (should .*)\./ =~ name
    [$1, $2]
  elsif /(.*)\(Test(.*)\)/ =~ name
    [$2, $1]
  end
end

module Test
  module Unit

    class Failure
      def filename_and_line
        location[0].to_s.sub(/\A(.+:\d+).*/, '\\1')
      end

      def long_display
        location_display = if(location.size == 1)
          " [#{filename_and_line}]"
        else
          "\n    [#{location.join("\n     ")}]"
        end
        name=(split=split_shoulda_names(@test_name))?split.join(" "):@test_name
        "#{name} FAILED: #{location_display}:\n    #@message"
      end
    end

    class Error
      def filename_and_line
        @exception.backtrace.first.to_s.sub(/\A(.+:\d+).*/, '\\1')
      end

      def long_display
        backtrace = filter_backtrace(@exception.backtrace).join("\n    ")
        name=(split=split_shoulda_names(@test_name))?split.join(" "):@test_name
        "#{@exception.class.name} in #{name}:\n#{message}\n    #{backtrace}"
      end
    end

    module UI
      module Console
        class TestRunner

          alias_method :test_started_old, :test_started
          
          def colors_enabled?
            return @colors_enabled unless @colors_enabled.nil?
            @colors_enabled = ENV['COLORS'].to_s.downcase != 'false'
          end
          
          def string_with_color(msg, color_sequence=nil)
            msg = "\e[#{color_sequence}m#{msg}\e[0m" if color_sequence && colors_enabled?
            msg
          end

          def test_started(name)
            ctx, should = split_shoulda_names(name)
            unless ctx.nil? or should.nil?
              if ctx != @ctx
                nl
                output(string_with_color(@suite.name, '0;34') + "\n" + string_with_color("#{ctx}: ", "0;34;1"))
              end

              @ctx = ctx
              @current_test_text = " ==> #{should}"
              #output_single("- #{should}: ")
            else
              test_started_old(name)
            end
          end

          def add_fault(fault)
            @faults << fault
            @already_outputted = true
          end

          def test_finished(name)
            # can cause issues if there's no test text.
            @current_test_text = ' ' if @current_test_text.nil? || @current_test_text.empty?
            if fault = @faults.find {|f| f.test_name == name}
              # Added ! to ERROR for length consistency
              fault_type = fault.is_a?(Test::Unit::Failure) ? "FAILED" : "ERROR!"

              output(
                "[" + string_with_color(fault_type, '0;31') + "]" +
                "#{@current_test_text} (#{@faults.length}) " +
                string_with_color(@faults.last.filename_and_line, "0;31")
              )
            else
              # Added spaces on either side of OK for length consistency
              output("[  " + string_with_color("OK", '0;32') + "  ]#{@current_test_text}")
            end
            @already_outputted = false
          end

        end
      end
    end
  end
end

