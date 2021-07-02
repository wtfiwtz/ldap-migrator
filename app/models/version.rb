class Version < ApplicationRecord
  # Inspired in part by the 'paper_trail'  and 'activerecord-diff' gems
  serialize :current
  serialize :diff

  belongs_to :model, polymorphic: true

  default_scope { order(created_at: :asc) }
end
