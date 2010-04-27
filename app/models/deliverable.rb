# == Schema Information
# Schema version: 20100427075741
#
# Table name: deliverables
#
#  id            :integer(4)      not null, primary key
#  assignment_id :integer(4)      not null
#  name          :string(80)      not null
#  description   :string(2048)    not null
#  published     :boolean(1)      not null
#  filename      :string(256)     default(""), not null
#  created_at    :datetime
#  updated_at    :datetime
#

class Deliverable < ActiveRecord::Base
  # The assignment that the deliverable is a part of.
  belongs_to :assignment
    
  # The user-visible assignment name.
  validates_length_of :name, :in => 1..64, :allow_nil => false
  # Instructions on preparing submissions for this deliverable.
  validates_length_of :description, :in => 1..(2.kilobytes), :allow_nil => false
  # If true, regular users can see this deliverable and submit to it.
  validates_inclusion_of :published, :in => [true, false]

  # The method used to verify students' submissions for this deliverable.
  has_one :deliverable_validation, :dependent => :destroy
  
  # All the student submissions for this deliverable.
  has_many :submissions, :dependent => :destroy
  
  # True if the given user should be allowed to see the deliverable.
  def visible_for_user?(user)
    published? or (user and user.admin?)
  end

  # This deliverable's submission for the given user.
  #
  # The result is non-trivial in the presence of teams.
  def submission_for_user(user)    
    if (partition = assignment.team_partition) and
       (team = partition.team_for_user(user))
      users = team.users
    else
      users = [user]
    end
    
    Submission.where(:deliverable_id => self.id, :user_id => users.map(&:id)).
               first
  end
  
  # The deliverables that a user is allowed to submit.
  def self.submittable_by_user(user)
    Deliverable.where(user.admin? ? {} : {:published => true})
  end
end
