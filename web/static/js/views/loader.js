import MainView from './main-view';
import RoomIndexView from './room/index';

const views = {
  RoomIndexView,
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}