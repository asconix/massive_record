module MassiveRecord
  module ORM
    module Relations
      class Proxy
        class ReferencesMany < Proxy


          def reset
            super
            @target = []
          end


          #
          # Adding record(s) to the collection.
          #
          def <<(*records)
            records.flatten.each do |record|
              unless include? record
                raise_if_type_mismatch(record)
                add_foreign_key_in_owner(record.id)
                target << record
              end
            end

            self
          end
          alias_method :push, :<<
          alias_method :concat, :<<

          #
          # Destroy record(s) from the collection
          # Each record will be asked to destroy itself as well
          #
          def destroy(*records)
            delete_or_destroy *records, :destroy
          end

          #
          # Destroy record(s) from the collection
          # Each record will be asked to delete itself as well
          #
          def delete(*records)
            delete_or_destroy *records, :delete
          end

          #
          # Checks if record is included in collection
          #
          # TODO  This needs a bit of work, depending on if proxy's target
          #       has been loaded or not. For now, we are just checking
          #       what we currently have in @target
          #
          def include?(record)
            target.include? record
          end

          private


          def delete_or_destroy(*records, method)
            records.flatten.each do |record|
              if include? record
                remove_foreign_key_in_owner(record.id)
                target.delete(record)
                record.send(method)
              end
            end
          end



          def find_target
            target_class.find(owner.send(foreign_key))
          end

          def find_target_with_proc
            [super].flatten
          end

          def can_find_target?
            super || owner.send(foreign_key).any? 
          end


          


          def add_foreign_key_in_owner(id)
            if owner.respond_to? foreign_key
              owner.send(foreign_key) << id
              notify_of_change_in_owner_foreign_key
            end
          end

          def remove_foreign_key_in_owner(id)
            if owner.respond_to? foreign_key
              owner.send(foreign_key).delete(id)
              notify_of_change_in_owner_foreign_key
            end
          end

          def notify_of_change_in_owner_foreign_key
            method = foreign_key+"_will_change!"
            owner.send(method) if owner.respond_to? method
          end
        end
      end
    end
  end
end
