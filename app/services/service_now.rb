# frozen_string_literal: true

require 'net/http'

class ServiceNow
  class << self
    TENANT = 'tenantname'
    API_ACCOUNT = 'apirequests'
    PASSWORD = ''
    PAGINATE_USERS = 500

    def user_list(offset = 0, limit = 20, https = true)
      request_path = "api/now/v2/table/sys_user?sysparm_offset=#{offset}&sysparm_limit=#{limit}"
      # sysparm_fields=user_name,first_name,last_name,sys_id&
      uri = URI.parse("https://#{TENANT}.service-now.com/#{request_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if https
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new(uri, 'Accept' => 'application/json')
      request.basic_auth(API_ACCOUNT, PASSWORD)
      response = http.request(request)
      raise "Invalid ServiceNow response! code=#{response.code}" unless
          response.code == '200'

      JSON.parse(response.body)
    end

    def user_get(sys_id = 'testsysid34234', https = true)
      request_path = "api/now/v2/table/sys_user/#{sys_id}"
      # sysparm_fields=user_name,first_name,last_name,sys_id&
      uri = URI.parse("https://#{TENANT}.service-now.com/#{request_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if https
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new(uri, 'Accept' => 'application/json')
      request.basic_auth(API_ACCOUNT, PASSWORD)
      response = http.request(request)
      raise "Invalid ServiceNow response! code=#{response.code}" unless
          response.code == '200'

      JSON.parse(response.body)
    end

    def user_create(https = true)
      details = {
          user_name: "smithni+test+creation@company.com",
          # sys_className: 'sys_user',
          employee_number: 'E11111',
          city: "Sydney",
          first_name: 'Nigel',
          email: 'Nigel.Sheridan-Smith+test+creation@company.com',
          locked_out: false,
          last_name: 'Sheridan-Smith (test creation)',
          middle_name: 'Bruce',
          time_zone: 'Australia/Sydney'
      }

      request_path = "api/now/v2/table/sys_user"
      # sysparm_fields=user_name,first_name,last_name,sys_id&
      uri = URI.parse("https://#{TENANT}.service-now.com/#{request_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if https
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.basic_auth(API_ACCOUNT, PASSWORD)
      request.body = details.to_json
      response = http.request(request)
      (puts response.body; raise "Invalid ServiceNow response! code=#{response.code}") unless
          response.code == '201'

      JSON.parse(response.body)
    end

    def load_from_connector(instance = 0)
      app_instance_details = { name: 'ServiceNow' }
      app_instance_details.merge(instance: instance) unless instance.zero?
      app = Application.where(app_instance_details).first_or_create!
      user_count = 0
      first = 0
      last = PAGINATE_USERS - 1
      loop do
        puts "Retrieving users: #{first}-#{last}"
        users = user_list(first, last, true)
        user_count += users.count
        app_users = users.collect { |user| map_user(app, user) }
        ApplicationUser.import(app_users)
        break if users.size < PAGINATE_USERS

        first += PAGINATE_USERS
        last = PAGINATE_USERS
      end
      puts "Loaded #{user_count} users."
    end

    def map_user(app, user)
      attrs = { application: app, all_attribs: user }
      attrs[:uuid] = user['sys_id']
      attrs[:first_name] = user['first_name']
      attrs[:middle_name] = user['middle_name']
      attrs[:last_name] = user['last_name']
      attrs[:title] = user['title']
      attrs[:gender] = user['gender']
      attrs[:email] = user['email']
      attrs[:disabled] = user['locked_out']
      attrs[:employee_number] = user['employee_number']
      attrs[:mobile_phone] = user['mobile_phone']
      attrs[:department] = user['department']
      attrs[:city] = user['city']
      ApplicationUser.new(attrs)
    end

    def user_disable(sys_id = 'testsysid34234', https = true)
      details = {
        locked_out: true
      }

      request_path = "api/now/v2/table/sys_user/#{sys_id}"
      # sysparm_fields=user_name,first_name,last_name,sys_id&
      uri = URI.parse("https://#{TENANT}.service-now.com/#{request_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if https
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Patch.new(uri, 'Content-Type' => 'application/json')
      request.basic_auth(API_ACCOUNT, PASSWORD)
      request.body = details.to_json
      response = http.request(request)
      (puts response.body; raise "Invalid ServiceNow response! code=#{response.code}") unless
          response.code == '200'

      JSON.parse(response.body)
    end

    def user_enable(sys_id = 'testsysid34234', https = true)
      details = {
          locked_out: false
      }

      request_path = "api/now/v2/table/sys_user/#{sys_id}"
      # sysparm_fields=user_name,first_name,last_name,sys_id&
      uri = URI.parse("https://#{TENANT}.service-now.com/#{request_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if https
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Patch.new(uri, 'Content-Type' => 'application/json')
      request.basic_auth(API_ACCOUNT, PASSWORD)
      request.body = details.to_json
      response = http.request(request)
      (puts response.body; raise "Invalid ServiceNow response! code=#{response.code}") unless
          response.code == '200'

      JSON.parse(response.body)
    end
  end
end
