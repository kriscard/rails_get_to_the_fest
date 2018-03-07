class MatchesController < ApplicationController
  def results
    rspotify = SpotifyArtistsService.new(user_hash: current_user.spotify_hash)
    @festival_array = []
    #List of festivals where there is at least one user's artist

    @festivals = Festival.all

    if params[:artist].present?
      @festivals = @festivals.search_by_artist(params[:artist])
    else
      # @festivals = @festivals.joins(line_ups: :artist).where("artists.name IN (?)", list_spotify_artists(rspotify))
      present_artists = current_user.user_artists
      @festivals.joins(line_ups: :artist).joins(artists: :user_artist).where("user_artist.name IN (?)", current_user.user_artists)
    end

    if params[:localisation].present?
      @festivals = @festivals.search_by_localisation(params[:localisation])
    end

    if params[:start_date].present?
      @start_date = params[:start_date].split(" to ").first
      @festivals = @festivals.where("date(start_date) >= ?", @start_date)
    end

    if params[:end_date].present?
      if params[:start_date] && params[:start_date].include?(" to ")
        @end_date = params[:start_date].split(" to ").last
      else
        @end_date = params[:end_date]
      end

      @festivals = @festivals.where("date(start_date) <= :end_date OR date(end_date) <= :end_date", end_date: @end_date)
    end

    # Thanks to pg_search we can't put a distinct...
    festival_ids = @festivals.pluck(:id)
    @festivals = Festival.where(id: festival_ids)

    @festivals.each do |festival|
      fest_hash = {
        festival_instance: festival,
        artists: list_artists_for_a_fest(rspotify, festival),
      }
      fest_hash[:affinity] = 0
      fest_hash[:artists].each do |artist_hash|
        fest_hash[:affinity] += artist_hash[:score]
      end
      fest_hash[:affinity] = 100 / 50 * fest_hash[:affinity]
      @festival_array <<  fest_hash
    end
    @festival_array.sort_by! { |festival_hash| festival_hash[:affinity] }.reverse!
  end

  private

  def list_spotify_artists(service)
    service.list_artists
  end

  def list_artists_for_a_fest(service, festival)
    service.favorites_artists(festival)
  end
end
