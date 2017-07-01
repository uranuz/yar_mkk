define('mkk/Pagination/Pagination', [
	'fir/controls/FirControl',
	'css!mkk/Pagination/Pagination'
], function(FirControl) {
	__extends(Pagination, FirControl);

	function Pagination(opts) {
		FirControl.call(this, opts);
		this._formField = opts.formField;
		// Если пользователь поменяет номер страницы в поле, то реально он не изменится до вызова setCurrentPage,
		// поэтому храним реальный номер в переменной
		this._currentPage = opts.currentPage;
		this._pageSize = opts.pageSize;
		this._offset = opts.offset;
		this._elems("prevBtn").on("click", this.gotoPrev.bind(this));
		this._elems("nextBtn").on("click", this.gotoNext.bind(this));
		this._elems("gotoPageBtn").on("click", this.gotoPage.bind(this));
	}

	return __mixinProto(Pagination, {
		/** Переход на предыдущую страницу */
		gotoPrev: function() {
			var page = this.getCurrentPage();
			this.setCurrentPage(page? page - 1: 0);
		},
		/** Переход на следующую страницу */
		gotoNext: function() {
			var page = this.getCurrentPage();
			this.setCurrentPage(page? page + 1: 1);
		},
		/** Переход на указанную пользователем в поле ввода страницу */
		gotoPage: function() {
			var userPageNum = parseInt(this._elems("currentPageField").val(), 10);
			this.setCurrentPage(userPageNum && userPageNum > 1? userPageNum - 1: 0);
		},
		/**
		 * Переход на страницу pageNum
		 * @param {number} pageNum - номер страницы (начинаются с 0)
		 */
		setCurrentPage: function(pageNum) {
			var closestForm = this._container.closest("form");
			this._currentPage = parseInt(pageNum, 10) || 0;
			// Хотя роботам это не понять, но пользователи привыкли, что номера страниц начинаются с 1
			this._elems("currentPageField").val(this._currentPage + 1);
			this._notify('onSetCurrentPage', this._currentPage);
			if( this._formField && closestForm.length ) {
				closestForm[0].submit();
			}
		},
		/** Получить номер текущей страницы (начинаются с 0)*/
		getCurrentPage: function() {
			var page = parseInt(this._currentPage, 10);
			return isNaN(page)? null: page;
		},
		/** Получить число страниц */
		getPageCount: function() {
			var page = parseInt(this._elems("pageCount").text(), 10);
			return isNaN(page)? null: page;
		},
		/**
		 * Метод, который нужно вызывать для установки навигационного состояния
		 * @param {object} nav - состояние навигации
		 * 	recordCount - число записей, по которым идёт навигация
		 * 	pageSize - размер страницы (не кол-во записей на текущей странице), возвращённый сервером 
		 * 	currentPage - номер текущей страницы (нумерация начинается с 0)
		 * 	offset - индекс первой записи страницы в списке записей, по которым идёт навигация (начинается с 0)
		 */
		setNavigation: function(nav) {
			if( nav.pageSize != null ) {
				this._pageSize =  nav.pageSize;
			}

			if( nav.pageCount != null ) {
				this._elems('pageCount').text(nav.pageCount);
			} else if( nav.recordCount != null && this._pageSize ) {
				this._elems('pageCount').text(Math.floor(nav.recordCount / this._pageSize));
			}

			this._elems('recordCount').text(nav.recordCount);
			if( nav.currentPage != null ) {
				this._elems('currentPage').text(nav.currentPage + 1);
				this._currentPage = nav.currentPage;
			} else if( nav.offset != null && this._pageSize ) {
				this._elems('currentPage').text(Math.floor(nav.offset / this._pageSize) + 1);
				this._offset = nav.offset;
			}

			this._setButtonsVisibility();
		},
		_setButtonsVisibility: function() {
			this._elems('prevBtn').css('visibility', (this._currentPage && this._currentPage > 1? 'visible': 'hidden'));
			this._elems('prevBtn').css('visibility', (this._currentPage && this._currentPage < this.getPageCount()? 'visible': 'hidden'));
			if( parseInt(this._elems('recordCount').text(), 10) < 0 ) {
				this._elems('notFoundMessage').show();
			} else {
				this._elems('notFoundMessage').hide();
			}
			
		}
	});
});