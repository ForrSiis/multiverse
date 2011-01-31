class CardsController < ApplicationController
  before_filter :find_cardset
  before_filter :only => [:new, :create, :edit, :update] do
    require_permission_to_edit(@cardset)
  end
  before_filter :only => :destroy do
    require_permission_to(:delete, @cardset)
  end
  before_filter do
    require_permission_to_view(@cardset)
  end

  helper CardsHelper

  def find_cardset
    if !params[:cardset_id].nil?
      @cardset = Cardset.find(params[:cardset_id])
    elsif !params[:id].nil?
      @card = Card.find(params[:id])
      @cardset = @card.cardset
    elsif params[:card] && !params[:card][:cardset_id].nil?
      @cardset = Cardset.find(params[:card][:cardset_id])
    else
      redirect_to root_path, :notice => "Cards must be in a cardset"
    end
  end

  # GET /cards/1
  # GET /cards/1.xml
  def show
    @card = Card.find(params[:id])
    @comment = Comment.new(:card => @card)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/new
  def new
    @card = Card.new(:cardset_id => params[:cardset_id])
    if params[:code] =~ Card.code_regexp
      @card.code = params[:code]
      @card.rarity, @card.frame = Card.interpret_code params[:code]
      Rails.logger.info "Detected valid code #{params[:code]}: using rarity #{@card.rarity} and frame #{@card.frame}"
    else
      @card.frame = "Auto"
      @card.rarity = "common"
    end
    unless @cardset && @cardset.new_record? 
      # why is this here? under what circumstances will I be going to /cards/new when the @cardset is a new_record?
      @cardset = Cardset.find(params[:cardset_id])
    end
  end

  # GET /cards/1/edit
  def edit
    @card = Card.find(params[:id])
    @render_frame = @card.frame
    if @card.calculated_frame == @card.frame
      @card.frame = "Auto"
      Rails.logger.info "Using Auto frame"
    else
      Rails.logger.info "Not using Auto frame as calculated_frame is '#{@card.calculated_frame}' but frame is '#{@card.frame}'..."
    end
  end

  def process_card
    if @card.attributes["frame"] == "Auto"
      @card.frame = @card.calculated_frame
      @card.save!
    end
  end

  # POST /cards
  def create
    @card = Card.new(params[:card])
    process_card
    set_last_edit @card

    if @card.save
      @cardset.log :kind=>:card_create, :user=>current_user, :object_id=>@card.id
      redirect_to @card, :notice => "#{@card.printable_name} was successfully created." 
    else
      render :action => "new"
    end
  end

  # PUT /cards/1
  def update
    @card = Card.find(params[:id])

    if @card.update_attributes(params[:card])
      process_card
      set_last_edit @card
      @cardset.log :kind=>:card_edit, :user=>current_user, :object_id=>@card.id

      redirect_to @card   #, :notice => 'Card was successfully updated.'
    else
      render :action => "edit"
    end
  end

  # DELETE /cards/1
  def destroy
    @card = Card.find(params[:id])
    @cardset = @card.cardset
    @card.destroy

    respond_to do |format|
      format.html do
        @cardset.log :kind=>:card_delete, :user=>current_user, :object_id=>@cardset.id
        redirect_to @cardset
      end
      # Horrible MVC violation, but I just can't get .js.erb files to render
      # Can only destroy cards via JS from the cardlist view
      format.js   do
        render :text => "$('card_row_#{params[:id]}').visualEffect('Fade', {'queue':'parallel'})" 
      end
    end
  end
end
