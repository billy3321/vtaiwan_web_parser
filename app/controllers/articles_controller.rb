class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :create]
  before_filter :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  # GET /articles
  # GET /articles.json
  def index
    @q = Article.search(params[:q])
    @articles = Article.search(params[:q]).result.page(params[:page])
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @comments = @article.comments.order(created_at: :asc).page params[:page]
    @comment = @article.comments.build
  end

  # GET /articles/new
  def new
    @article = Article.new
    @comment = @article.comments.build
  end

  # GET /articles/1/edit
  def edit
    @comment = @article.comments.build
  end

  # POST /articles
  def create
    if @article.save
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /articles/1
  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /articles/1
  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = params[:id] ? Article.find(params[:id]) : Article.new(article_params)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:user_id, :source_url, :comment_authors)
    end
end
