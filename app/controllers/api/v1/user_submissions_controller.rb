module Api
  module V1
    class UserSubmissionsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      has_scope :region

      api :GET, '/api/v1/region/:region/user_submissions.json', 'Fetch user submissions for a single region'
      param :region, String, desc: 'Name of the Region you want to see user submissions for', required: true
      def index
        user_submissions = apply_scopes(UserSubmission)
        user_submissions = user_submissions.select { |s| s.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }

        return_response(user_submissions, 'user_submissions')
      end

      MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS = 5

      api :GET, '/api/v1/user_submissions/list_within_range.json', 'Fetch user submissions within N miles of provided lat/lon'
      param :lat, String, desc: 'Latitude', required: true
      param :lon, String, desc: 'Longitude', required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles', required: false
      param :min_date_of_submission, String, desc: 'Earliest date to consider updates from, format YYYY-MM-DD', required: false
      param :submission_type, String, desc: 'Type of submission to filter to', required: false
      def list_within_range
        max_distance = params[:max_distance] ||= MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS
        min_date_of_submission = params[:min_date_of_submission] ? params[:min_date_of_submission].to_date : 1.month.ago

        locations = apply_scopes(Location).near([params[:lat], params[:lon]], max_distance)

        user_submissions = nil
        if params[:submission_type]
          user_submissions = UserSubmission.where(created_at: min_date_of_submission..Date.today, location_id: locations.map(&:id), submission_type: params[:submission_type])
        else
          user_submissions = UserSubmission.where(created_at: min_date_of_submission..Date.today, location_id: locations.map(&:id))
        end

        return_response(user_submissions, 'user_submissions')
      end
    end
  end
end
