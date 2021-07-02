# frozen_string_literal: true

require 'net/ldap'

class Ldap
  class << self
    LDAP_USERNAME = ''
    LDAP_PASSWORD = ''
    PAGINATE_MEMBERS = 1500
    LDAP_USER_ATTRIBUTES = %w[objectguid objectsid cn objectclass givenname sn mail useraccountcontrol title c l co department company st description
                              physicaldeliveryofficename telephonenumber whencreated whenchanged info memberof
                              homedirectory profilepath samaccountname accountexpires userprincipalname manager
                              employeeid division departmentnumber].freeze
    LDAP_GROUP_ATTRIBUTES = %w[objectclass cn description distinguishedname instancetype whencreated whenchanged usncreated
                               usnchanged admindisplayname admindescription name objectguid objectsid samaccountname
                               samaccounttype grouptype objectcategory]

    # Account disabling - https://docs.microsoft.com/en-us/windows/win32/adschema/a-useraccountcontrol?redirectedfrom=MSDN
    # 0x00000002	ADS_UF_ACCOUNTDISABLE
    # 0x00000010	ADS_UF_LOCKOUT
    # 0x00000200	ADS_UF_NORMAL_ACCOUNT
    # 0x00010000	ADS_UF_DONT_EXPIRE_PASSWD
    # 0x00800000	ADS_UF_PASSWORD_EXPIRED

    # Pagination:
    #   Use "0" for unlimited and Net::LDAP will automatically paginate (if available)
    #   https://github.com/ruby-ldap/ruby-net-ldap/blob/9daa954061c2a071345bd18d462db5af8acfe8a0/lib/net/ldap/connection.rb#L343
    LDAP_LIMIT = 0 # 80

    def user_search(search_base, limit = LDAP_LIMIT, server = '')
      ldap = Net::LDAP.new(host: server, port: 389,
                           auth: { method: :simple, username: LDAP_USERNAME, password: LDAP_PASSWORD })
      filter = Net::LDAP::Filter.join(Net::LDAP::Filter.eq('objectclass', 'user'), Net::LDAP::Filter.ne('objectclass', 'computer'))

      entries = []
      puts "Starting search... #{search_base}; #{filter.to_s}"
      cn_set = []
      ldap.search(base: search_base, filter: filter, size: limit, attributes: LDAP_USER_ATTRIBUTES) do |entry|
        cn_set.push(entry.cn)
        # puts "Loading DN: #{entry.dn}"
        hsh = entry.as_json['myhash'].collect do |h, v|
          if %w[objectclass memberof].include?(h)
            { h => v }
          elsif %w[objectsid].include?(h)
            { h => v } # .force_encoding('UTF-8')
          else
            { h => v.join(', ') }
          end
        end.reduce({}, :merge)
        entries.push(hsh)
        # ap hsh
      end
      puts "... #{cn_set}"
      unless [0, 4].include?(ldap.get_operation_result[:code]) # 4 = Size Exceeded
        puts "Error #{ldap.get_operation_result[:code]}: #{ldap.get_operation_result[:message]}"
        raise Exception.new(ldap.get_operation_result[:message])
      end

      entries
    end

    def user_import(limit = LDAP_LIMIT)
      search_base = 'ou=Users,dc=orgname,dc=corp'
      entries = user_search(search_base, limit)
      users = entries.collect { |x| LdapUser.new(x) }
      time = Time.now
      LdapUser.import(users, on_duplicate_key_update: {conflict_target: [:objectguid],
                                                       columns: %w[cn givenname sn mail useraccountcontrol title c l co department company st description
                                                                   physicaldeliveryofficename telephonenumber whencreated whenchanged info memberof
                                                                   homedirectory profilepath samaccountname accountexpires userprincipalname manager
                                                                   employeeid division departmentnumber objectsid]})

      results = handle_user_versions(time)

      # puts "** Created user IDs: #{results[:created_ids]}"
      # puts "** Updated user IDs: #{results[:updated_ids]}"
      # ap LdapUser.find(results[:updated_ids]) if results[:updated_ids].any?

      results
    end

    def handle_user_versions(time)
      created = []
      updated = []
      updated_users = LdapUser.where('updated_at >= ?', time)
      recent_versions = Version.select('MAX(created_at),model_type,model_id,current')\
                               .where(model_type: 'LdapUser', model_id: updated_users.pluck(:id)).group(:model_id)
      updated_users.each do |user|
        if user.created_at == user.updated_at
          created.push(user.versions.create!(current: user.attributes, diff: nil))
        else
          last_version = recent_versions.detect { |ver| ver[:model_id] == user.id }
          raise "No last version for LDAP user: #{user.id}" unless last_version
          diff = Diff.diff(last_version.current, user.attributes, %w[updated_at])
          updated.push(user.versions.create!(current: user.attributes, diff: diff)) unless diff.empty?
        end
      end

      { created_ids: created.collect(&:model_id), updated_ids: updated.collect(&:model_id) }
    end

    def group_search(search_base, limit = LDAP_LIMIT, server = '')
      ldap = Net::LDAP.new(host: server, port: 389,
                           auth: { method: :simple, username: LDAP_USERNAME, password: LDAP_PASSWORD })
      filter = Net::LDAP::Filter.eq('objectclass', 'group')

      entries = []
      retrieve_all_members = []

      ldap.search(base: search_base, filter: filter, size: limit,
                  attributes: LDAP_GROUP_ATTRIBUTES + ['member;range=0-*']) do |entry|
        too_many_members = false
        puts "Loading DN: #{entry.dn}"
        hsh = entry.as_json['myhash'].collect do |h, v|
          if %w[objectclass].include?(h)
            { h => v }
          elsif h.start_with?('member')
            puts("  #{{ h => v.size }}") if h != 'member' and not h.end_with?('*')
            too_many_members = true unless h.end_with?('*')
            { 'member' => v }
          elsif %w[objectsid].include?(h)
            { h => v } # .force_encoding('UTF-8')
          else
            { h => v.join(', ') }
          end
        end.reduce({}, :merge)
        retrieve_all_members.push(hsh) if too_many_members
        entries.push(hsh)
      end
      # ap ldap.get_operation_result

      retrieve_all_group_members(ldap, filter, retrieve_all_members) if retrieve_all_members.any?
      entries
    end

    def retrieve_all_group_members(ldap, filter, ary)
      ary.each do |hsh|
        all_members = []
        first = 0
        last = PAGINATE_MEMBERS - 1
        loop do
          ldap.search(base: hsh['dn'], filter: filter, size: LDAP_LIMIT, attributes: LDAP_GROUP_ATTRIBUTES + ["member;range=#{first}-#{last}"]) do |entry|
            puts "  Loading full membership for DN: #{entry.dn}; range=#{first}-#{last}"
            _hsh2 = entry.as_json['myhash'].collect do |h, v|
              if %w[objectclass].include?(h)
                { h => v }
              elsif h.start_with?('member')
                puts("    #{{ h => v.size }}") if h != 'member' and not h.end_with?('*')
                all_members.concat(v)
                { 'member' => v }
              elsif %w[objectsid].include?(h)
                { h => v } # .force_encoding('UTF-8')
              else
                { h => v.join(', ') }
              end
            end.reduce({}, :merge)
          end
          break if all_members.count < last + 1

          first += PAGINATE_MEMBERS
          last += PAGINATE_MEMBERS
        end
        puts "  *** Total count = #{all_members.count}"
        # puts "      Keys: #{hsh.keys}"
        hsh['member'] = all_members
      end
    end

    def group_import(limit = LDAP_LIMIT)
      search_base = 'OU=Groups,DC=orgname,DC=corp'
      entries = group_search(search_base, limit)
      groups = entries.collect { |x| LdapGroup.new(x) }
      LdapGroup.import(groups, on_duplicate_key_update: { conflict_target: [:objectguid],
                                                          columns: %w[objectclass cn description distinguishedname instancetype whencreated whenchanged usncreated
                                                                      member usnchanged admindisplayname admindescription name objectsid samaccountname
                                                                      samaccounttype grouptype objectcategory]})
    end

    def update_group_memberships(flush = false)
      # TODO: This only appends, it doesn't clean up removed group memberships; set flush=true to remove all entries and
      # start again
      GroupMembership.delete_all if flush
      LdapGroup.includes(:group_memberships).find_in_batches do |batch|
        batch.each do |group|
          existing_ldap_user_ids = group.group_memberships.collect(&:ldap_user_id)
          user_ids = LdapUser.where(dn: group.member).pluck(:id)
          group_memberships = (user_ids.sort - existing_ldap_user_ids).uniq.collect do |user_id|
            GroupMembership.new(ldap_group_id: group.id, ldap_user_id: user_id)
          end
          GroupMembership.import(group_memberships)
        end
      end
    end
  end
end
