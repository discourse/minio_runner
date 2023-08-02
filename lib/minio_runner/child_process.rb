# frozen_string_literal: true

# Copied with modification from https://github.com/SeleniumHQ/selenium/

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module MinioRunner
  #
  # @api private
  #

  class ChildProcess
    TimeoutError = Class.new(StandardError)

    SIGTERM = "TERM"
    SIGKILL = "KILL"

    POLL_INTERVAL = 0.1

    attr_accessor :detach
    attr_writer :io
    attr_reader :pid

    def self.build(command, env: {}, log_file: File::NULL)
      new(command, env: env, log_file: log_file)
    end

    def initialize(command, env: {}, log_file: File::NULL)
      @command = command
      @detach = false
      @pid = nil
      @status = nil
      @env = env
      @log_file = log_file
    end

    def io
      @io ||= File::NULL
    end

    def start
      options = { %i[out err] => @log_file }

      # TODO (martin) Maybe don't log ENV here?
      MinioRunner.logger.debug("Starting process: #{@command} with #{options} and ENV #{@env}")
      @pid = Process.spawn(@env, @command.join(" "), options)
      MinioRunner.logger.debug("  -> pid: #{@pid}")

      Process.detach(@pid) if detach
    end

    def stop(timeout = 3)
      return unless @pid
      return if exited?

      MinioRunner.logger.debug("Sending TERM to process: #{@pid}")
      terminate(@pid)
      poll_for_exit(timeout)

      MinioRunner.logger.debug("  -> stopped #{@pid}")
    rescue TimeoutError, Errno::EINVAL
      MinioRunner.logger.debug("    -> sending KILL to process: #{@pid}")
      kill(@pid)
      wait
      MinioRunner.logger.debug("      -> killed #{@pid}")
    end

    def alive?
      @pid && !exited?
    end

    def exited?
      return unless @pid

      MinioRunner.logger.debug("Checking if #{@pid} is exited:")
      _, @status = Process.waitpid2(@pid, Process::WNOHANG | Process::WUNTRACED) if @status.nil?
      return if @status.nil?

      exit_code = @status.exitstatus || @status.termsig
      MinioRunner.logger.debug("  -> exit code is #{exit_code.inspect}")

      !!exit_code
    end

    def poll_for_exit(timeout)
      MinioRunner.logger.debug("Polling #{timeout} seconds for exit of #{@pid}")

      end_time = Time.now + timeout
      sleep POLL_INTERVAL until exited? || Time.now > end_time

      raise TimeoutError, "  ->  #{@pid} still alive after #{timeout} seconds" unless exited?
    end

    def wait
      return if exited?

      _, @status = Process.waitpid2(@pid)
    end

    private

    def terminate(pid)
      Process.kill(SIGTERM, pid)
    end

    def kill(pid)
      Process.kill(SIGKILL, pid)
    rescue Errno::ECHILD, Errno::ESRCH
      # already dead
    end
  end # ChildProcess
end # MinioRunner
