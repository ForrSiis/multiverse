class DetailsPagesController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
    require_permission_to_view(@cardset)
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_permission_to_admin(@cardset)
  end

  # GET /details_pages/1
  # GET /details_pages/1.xml
  def show
    @details_page = DetailsPage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @details_page }
    end
  end

  # GET /details_pages/new
  def new
    @details_page = @cardset.details_pages.build  # DetailsPage.new
  end

  # GET /details_pages/1/edit
  def edit
    @details_page = DetailsPage.find(params[:id])
  end

  # POST /details_pages
  def create
    @details_page = @cardset.details_pages.build(params[:details_page])

    if @details_page.save
      set_last_edit(@details_page)
      redirect_to([@cardset, @details_page], :notice => 'Details page was successfully created.')
    else
      render :action => "new"
    end
  end

  # PUT /details_pages/1
  # PUT /details_pages/1.js
  def update
    @details_page = DetailsPage.find(params[:id])

    if params[:details_page][:order]
      # Do something completely different for reorderings
      @details_page.set_order(params[:details_page][:order])
      respond_to do |format|
        format.js { }
        format.html { redirect_to([@cardset, @details_page]) }
      end

    else
      # Normal update
      if @details_page.update_attributes(params[:details_page])
        set_last_edit(@details_page)
        redirect_to([@cardset, @details_page], :notice => 'Details page was successfully updated.')
      else
        render :action => "edit"
      end
    end
  end

  # DELETE /details_pages/1
  def destroy
    @details_page = DetailsPage.find(params[:id])
    @details_page.destroy

    redirect_to(@cardset)
  end
end
