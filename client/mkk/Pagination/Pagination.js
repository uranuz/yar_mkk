define('mkk/Pagination/Pagination', [
	'fir/controls/FirControl',
	'css!mkk/Pagination/Pagination'
], function(FirControl) {
	__extends(Pagination, FirControl);
	var PaginationMode = {
		Offset: 0,
		Page: 1
	};

	function Pagination(opts) {
		FirControl.call(this, opts);
		this._formField = opts.formField;
		this._pageSizeFormField = opts.pageSizeFormField;

		// Пытаемся определить тип постраничной нафигации на основе того, какая опция задана.
		// По-умолчанию предполагаем режим с использованием offset (сдвига по записям)
		if( opts.currentPage != null ) {
			this.setPaginationMode(PaginationMode.Page);
		} else {
			this.setPaginationMode(PaginationMode.Offset);
		}
		this.setPageSize(opts.pageSize);

		this._elems('firstBtn').on('click', this.gotoFirst.bind(this));
		this._elems('prevBtn').on('click', this.gotoPrev.bind(this));
		this._elems('nextBtn').on('click', this.gotoNext.bind(this));
		this._elems('lastBtn').on('click', this.gotoLast.bind(this));
		this._elems('gotoPageBtn').on('click', this.gotoPage.bind(this));

		this._setButtonsVisibility();
	}

	return __mixinProto(Pagination, {
		/** Переход на первую страницу */
		gotoFirst: function() {
			this.setCurrentPage(0);
		},
		/** Переход на последнюю страницу */
		gotoLast: function() {
			var pageCount = this.getPageCount();
			this.setCurrentPage(pageCount? pageCount - 1: 0);
		},
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
			var userPageNum = parseInt(this._elems('currentPageField').val(), 10);
			this.setCurrentPage(userPageNum && userPageNum > 1? userPageNum - 1: 0);
		},
		/**
		 * Переход на страницу pageNum
		 * @param {number} pageNum - номер страницы (начинаются с 0)
		 */
		setCurrentPage: function(pageNum) {
			var closestForm = this._container.closest('form');
			this._elems('pageHiddenField').val(parseInt(pageNum, 10) || 0);
			this._elems('offsetField').val(parseInt(pageNum, 10) * this.getPageSize() || 0);

			// Хотя роботам это не понять, но пользователи привыкли, что номера страниц начинаются с 1
			this._elems('currentPageField').val(this.getCurrentPage() + 1);
			this._notify('onSetCurrentPage', this.getCurrentPage());
			if( this._formField && closestForm.length ) {
				closestForm[0].submit();
			}
		},
		/** Получить номер текущей страницы (начинаются с 0)*/
		getCurrentPage: function() {
			var page;
			if( this._mode == PaginationMode.Page ) {
				page = parseInt(this._elems('pageHiddenField').val(), 10);
			} else {
				page = Math.floor(parseInt(this._elems('offsetField').val(), 10) / this.getPageSize());
			}
			return isNaN(page)? null: page;
		},
		getOffset: function() {
			var offset;
			if( this._mode == PaginationMode.Page ) {
				offset = parseInt(this._elems('pageHiddenField').val()) * this.getPageSize();
			} else {
				offset = parseInt(this._elems('offsetField').val(), 10);
			}
			return isNaN(offset)? null: offset;
		},
		/** Получить число страниц */
		getPageCount: function() {
			var page = parseInt(this._elems('pageCount').text(), 10);
			return isNaN(page)? null: page;
		},
		getPageSize: function() {
			var pageSize = parseInt(this._elems('pageSizeField').val(), 10);
			return isNaN(pageSize)? null: pageSize;
		},
		setPaginationMode: function(mode) {
			if( [PaginationMode.Page, PaginationMode.Offset].indexOf(mode) < 0 ) {
				throw new Error('Invalid navigation mode: ' + mode);
			}
			this._mode = mode;
			switch(this._mode) {
				case PaginationMode.Offset: {
					this._elems('pageHiddenField').attr('name', null);
					this._elems('offsetField').attr('name', this._formField);
					break;
				}
				case PaginationMode.Page: {
					this._elems('pageHiddenField').attr('name', this._formField);
					this._elems('offsetField').attr('name', null);
					break;
				}
				default: break;
			}
		},
		setPageSize: function(pageSize) {
			if( pageSize === null ) {
				return;
			}
			this._elems('pageSizeField').val(pageSize);
			if( this.pageSizeFormField ) {
				this._elems('pageSizeField').attr('name', this.pageSizeFormField);
			}
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
			this.setPageSize(nav.pageSize);

			// Пытаемся уточнить режим постраничной навигации по возвращённой структуре
			if( nav.currentPage != null && nav.offset == null ) {
				this.setPaginationMode(PaginationMode.Page);
			} else if( nav.offset != null ) {
				this.setPaginationMode(PaginationMode.Offset);
			} // else: Режим навигации не изменился

			// Обновляем значения основных полей изходя из полученной стуктуры навигации,
			// либо используя старые значения, если в структуре не соотв. полей
			if (nav.currentPage != null) {
				this._elems('pageHiddenField').val(parseInt(nav.currentPage, 10) || 0);
			} else {
				this._elems('pageHiddenField').val((this.getCurrentPage() || 0) + 1);
			}
			if (nav.offset != null) {
				this._elems('offsetField').val(parseInt(nav.offset, 10) || 0);
			} else {
				this._elems('offsetField').val((this.getOffset() || 0) + this.getPageSize());
			}

			this._renderNavData(nav);
			this._setButtonsVisibility();
		},
		_renderNavData: function(nav) {
			var
				page = this.getCurrentPage(),
				offset = this.getOffset(),
				pageSize = this.getPageSize();
			this._elems('currentPageField').val(page? page + 1: 1);
			if( nav.pageCount != null ) {
				this._elems('pageCount').text(nav.pageCount);
			} else if( nav.recordCount != null && pageSize ) {
				this._elems('pageCount').text(Math.ceil(nav.recordCount / pageSize));
			}

			this._elems('recordCount').text(nav.recordCount);
		},
		_setButtonsVisibility: function() {
			var
				page = this.getCurrentPage(),
				pageCount = this.getPageCount(),
				isFirstVisible = (page != null && page < 1? 'hidden': 'visible'),
				isLastVisible = (page != null && pageCount != null && page + 1 >= pageCount? 'hidden': 'visible'),
				recordCount = parseInt(this._elems('recordCount').text(), 10);
			this._elems('prevBtn').css('visibility', isFirstVisible);
			this._elems('firstBtn').css('visibility', isFirstVisible);
			this._elems('nextBtn').css('visibility', isLastVisible);
			this._elems('lastBtn').css('visibility', isLastVisible);

			if( isNaN(recordCount) ) {
				this._elems('notFoundMsg').hide();
				this._elems('recordCountMsg').hide();
			} else if( recordCount > 0 ) {
				this._elems('notFoundMsg').hide();
				this._elems('recordCountMsg').show();
			} else {
				this._elems('notFoundMsg').show();
				this._elems('recordCountMsg').hide();
			}
		}
	});
});